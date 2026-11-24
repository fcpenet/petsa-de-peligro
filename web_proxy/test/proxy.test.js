import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  handlePipeline,
  pipelineUrl,
  resetCertsCache,
  verifyAccessJwt,
} from '../src/proxy.js';

const TEAM = 'petsa.cloudflareaccess.com';
const AUD = 'aud-123';
const env = {
  TURSO_URL: 'libsql://petsa-x.turso.io',
  TURSO_TOKEN: 'secret-token',
  ACCESS_TEAM: TEAM,
  ACCESS_AUD: AUD,
};

const b64url = (bytes) =>
  Buffer.from(bytes).toString('base64').replace(/=+$/, '')
    .replace(/\+/g, '-').replace(/\//g, '_');

const keyPair = await crypto.subtle.generateKey(
  {
    name: 'RSASSA-PKCS1-v1_5',
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: 'SHA-256',
  },
  true,
  ['sign', 'verify'],
);
const publicJwk = {
  ...(await crypto.subtle.exportKey('jwk', keyPair.publicKey)),
  kid: 'k1',
};

async function sign(overrides = {}, { kid = 'k1', key = keyPair.privateKey } = {}) {
  const header = { alg: 'RS256', kid };
  const payload = {
    aud: [AUD],
    iss: `https://${TEAM}`,
    email: 'me@example.com',
    exp: Math.floor(Date.now() / 1000) + 600,
    ...overrides,
  };
  const enc = (o) => b64url(new TextEncoder().encode(JSON.stringify(o)));
  const data = `${enc(header)}.${enc(payload)}`;
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(data));
  return `${data}.${b64url(new Uint8Array(sig))}`;
}

/** Fake fetch: serves Access certs and records/answers Turso calls. */
function fakeFetch(tursoResponse = { status: 200, body: { baton: 'b1', base_url: 'https://direct.turso.io', results: [] } }) {
  const calls = [];
  const impl = async (url, init) => {
    calls.push({ url: `${url}`, init });
    if (`${url}`.endsWith('/cdn-cgi/access/certs')) {
      return Response.json({ keys: [publicJwk] });
    }
    return new Response(JSON.stringify(tursoResponse.body), { status: tursoResponse.status });
  };
  impl.calls = calls;
  impl.tursoCalls = () => calls.filter((c) => c.url.endsWith('/v3/pipeline'));
  return impl;
}

const pipelineRequest = (jwt, { method = 'POST' } = {}) =>
  new Request('https://petsa.pages.dev/v3/pipeline', {
    method,
    headers: jwt ? { 'Cf-Access-Jwt-Assertion': jwt } : {},
    body: method === 'POST' ? '{"baton":null,"requests":[]}' : undefined,
  });

beforeEach(() => resetCertsCache());

test('pipelineUrl maps libsql and https URLs', () => {
  assert.equal(pipelineUrl('libsql://db.turso.io'), 'https://db.turso.io/v3/pipeline');
  assert.equal(pipelineUrl('https://db.turso.io'), 'https://db.turso.io/v3/pipeline');
});

test('forwards a signed-in request with the Turso token', async () => {
  const f = fakeFetch();
  const res = await handlePipeline(pipelineRequest(await sign()), env, f);
  assert.equal(res.status, 200);
  const [call] = f.tursoCalls();
  assert.equal(call.url, 'https://petsa-x.turso.io/v3/pipeline');
  assert.equal(call.init.headers.Authorization, 'Bearer secret-token');
  assert.equal(call.init.body, '{"baton":null,"requests":[]}');
});

test('strips base_url so the app keeps using the proxy', async () => {
  const res = await handlePipeline(pipelineRequest(await sign()), env, fakeFetch());
  const body = await res.json();
  assert.equal(body.baton, 'b1');
  assert.equal('base_url' in body, false);
});

test('never returns the Turso token', async () => {
  const res = await handlePipeline(pipelineRequest(await sign()), env, fakeFetch());
  assert.equal((await res.text()).includes('secret-token'), false);
});

test('passes Turso errors through with their status', async () => {
  const f = fakeFetch({ status: 400, body: { error: { message: 'bad sql' } } });
  const res = await handlePipeline(pipelineRequest(await sign()), env, f);
  assert.equal(res.status, 400);
  assert.equal((await res.json()).error.message, 'bad sql');
});

for (const [name, makeJwt] of [
  ['no token', async () => null],
  ['garbage token', async () => 'not.a.jwt'],
  ['expired token', () => sign({ exp: Math.floor(Date.now() / 1000) - 1 })],
  ['wrong audience', () => sign({ aud: ['someone-else'] })],
  ['wrong issuer', () => sign({ iss: 'https://evil.cloudflareaccess.com' })],
  ['unknown key id', () => sign({}, { kid: 'other' })],
]) {
  test(`rejects ${name} without calling Turso`, async () => {
    const f = fakeFetch();
    const res = await handlePipeline(pipelineRequest(await makeJwt()), env, f);
    assert.equal(res.status, 401);
    assert.equal(f.tursoCalls().length, 0);
  });
}

test('rejects a token signed by a different key', async () => {
  const other = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify']);
  const f = fakeFetch();
  const res = await handlePipeline(pipelineRequest(await sign({}, { key: other.privateKey })), env, f);
  assert.equal(res.status, 401);
  assert.equal(f.tursoCalls().length, 0);
});

test('ALLOWED_EMAILS limits who gets through', async () => {
  const limited = { ...env, ALLOWED_EMAILS: 'Me@Example.com, other@example.com' };
  const ok = await handlePipeline(pipelineRequest(await sign()), limited, fakeFetch());
  assert.equal(ok.status, 200);
  const f = fakeFetch();
  const no = await handlePipeline(
    pipelineRequest(await sign({ email: 'stranger@example.com' })), limited, f);
  assert.equal(no.status, 401);
  assert.equal(f.tursoCalls().length, 0);
});

test('fails closed when not configured', async () => {
  const f = fakeFetch();
  const res = await handlePipeline(
    pipelineRequest(await sign()), { ...env, ACCESS_AUD: undefined }, f);
  assert.equal(res.status, 500);
  assert.equal(f.calls.length, 0);
});

test('rejects non-POST methods', async () => {
  const res = await handlePipeline(pipelineRequest(null, { method: 'GET' }), env, fakeFetch());
  assert.equal(res.status, 405);
});

test('caches Access signing keys between requests', async () => {
  const f = fakeFetch();
  await handlePipeline(pipelineRequest(await sign()), env, f);
  await handlePipeline(pipelineRequest(await sign()), env, f);
  assert.equal(f.calls.filter((c) => c.url.endsWith('/certs')).length, 1);
});

test('verifyAccessJwt returns the payload', async () => {
  const payload = await verifyAccessJwt(await sign(), env, fakeFetch());
  assert.equal(payload.email, 'me@example.com');
});
