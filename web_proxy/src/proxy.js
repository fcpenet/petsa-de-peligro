// Turso proxy for the web build.
//
// The browser sends Hrana v3 pipeline requests here without any token. This
// code checks the Cloudflare Access login, adds the Turso token (a secret
// that never leaves Cloudflare) and forwards the request to Turso.
//
// Required environment (Pages project settings / secrets):
//   TURSO_URL       libsql:// or https:// URL of the production database
//   TURSO_TOKEN     Turso auth token (secret)
//   ACCESS_TEAM     Zero Trust team domain, e.g. "petsa.cloudflareaccess.com"
//   ACCESS_AUD      Application Audience (AUD) tag of the Access application
// Optional:
//   ALLOWED_EMAILS  comma-separated emails; when set, others are rejected even
//                   if Access let them through

const CERTS_TTL_MS = 60 * 60 * 1000;
let certsCache = { team: null, keys: null, at: 0 };

/** Test hook: forget cached Access signing keys. */
export function resetCertsCache() {
  certsCache = { team: null, keys: null, at: 0 };
}

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

const fail = (status, message) => json(status, { error: { message } });

function base64UrlDecode(input) {
  const base64 = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

const decodeJson = (part) =>
  JSON.parse(new TextDecoder().decode(base64UrlDecode(part)));

async function accessKeys(team, fetchImpl) {
  const fresh = Date.now() - certsCache.at < CERTS_TTL_MS;
  if (certsCache.team === team && certsCache.keys && fresh) {
    return certsCache.keys;
  }
  const res = await fetchImpl(`https://${team}/cdn-cgi/access/certs`);
  if (!res.ok) throw new Error(`certs HTTP ${res.status}`);
  const { keys } = await res.json();
  certsCache = { team, keys, at: Date.now() };
  return keys;
}

/**
 * Verifies a Cloudflare Access JWT. Returns its payload, or throws with a
 * short reason.
 */
export async function verifyAccessJwt(token, env, fetchImpl = fetch) {
  const parts = (token || '').split('.');
  if (parts.length !== 3) throw new Error('missing or malformed token');
  const [headerPart, payloadPart, signaturePart] = parts;
  const header = decodeJson(headerPart);
  const payload = decodeJson(payloadPart);
  if (header.alg !== 'RS256') throw new Error('unexpected algorithm');

  const keys = await accessKeys(env.ACCESS_TEAM, fetchImpl);
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new Error('unknown signing key');
  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    base64UrlDecode(signaturePart),
    new TextEncoder().encode(`${headerPart}.${payloadPart}`),
  );
  if (!valid) throw new Error('bad signature');

  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.exp !== 'number' || payload.exp <= now) {
    throw new Error('expired');
  }
  if (payload.iss !== `https://${env.ACCESS_TEAM}`) {
    throw new Error('wrong issuer');
  }
  const aud = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
  if (!aud.includes(env.ACCESS_AUD)) throw new Error('wrong audience');

  const allowed = (env.ALLOWED_EMAILS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  if (allowed.length && !allowed.includes(`${payload.email}`.toLowerCase())) {
    throw new Error('email not allowed');
  }
  return payload;
}

/** `libsql://host` → `https://host/v3/pipeline`. */
export function pipelineUrl(tursoUrl) {
  const url = new URL(tursoUrl);
  if (url.protocol === 'libsql:' || url.protocol === 'wss:') {
    return `https://${url.host}/v3/pipeline`;
  }
  return new URL('/v3/pipeline', url).toString();
}

/** Handles one request to /v3/pipeline. */
export async function handlePipeline(request, env, fetchImpl = fetch) {
  if (request.method !== 'POST') return fail(405, 'POST only');
  const missing = ['TURSO_URL', 'TURSO_TOKEN', 'ACCESS_TEAM', 'ACCESS_AUD']
    .filter((name) => !env[name]);
  if (missing.length) {
    // Fail closed: never forward without being able to check the login.
    return fail(500, `proxy not configured: ${missing.join(', ')}`);
  }

  try {
    await verifyAccessJwt(
      request.headers.get('Cf-Access-Jwt-Assertion'),
      env,
      fetchImpl,
    );
  } catch (e) {
    return fail(401, `not signed in (${e.message})`);
  }

  const upstream = await fetchImpl(pipelineUrl(env.TURSO_URL), {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.TURSO_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: await request.text(),
  });

  const text = await upstream.text();
  if (!upstream.ok) {
    return new Response(text, {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  // Drop base_url so the app keeps talking to this proxy instead of
  // following Turso's direct host (which would need the token).
  const body = JSON.parse(text);
  delete body.base_url;
  return json(200, body);
}
