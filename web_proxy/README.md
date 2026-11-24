# Web deployment (Cloudflare Pages + Access)

The web app is static files plus one Pages Function, `functions/v3/pipeline.js`,
served at `/v3/pipeline` on the same site. The app is built with
`TURSO_URL=/` and **no token**. The function:

1. checks the Cloudflare Access login (the signed `Cf-Access-Jwt-Assertion`
   header) and, optionally, an email allow-list,
2. adds the Turso token, which is stored only as a Cloudflare secret,
3. forwards the request to Turso, and removes `base_url` from the response so
   the app never talks to Turso directly.

If any setting is missing, it refuses every request.

## Deploy

```sh
tool/deploy_web.sh           # production
tool/deploy_web.sh preview   # preview URL only
```

The script runs the tests, builds, checks that no Turso token ended up in
`build/web`, and runs `wrangler pages deploy`.

## One-time setup

1. `npx wrangler login`
2. Create the project: `npx wrangler pages project create petsa --production-branch main`
3. Create a production Turso token: `turso db tokens create petsa`. Check that
   the output starts with `eyJ`: when the CLI isn't logged in
   (`turso auth login`), it prints an error but still exits successfully.
4. Set the settings (each command prompts for the value):
   ```sh
   cd web_proxy
   npx wrangler pages secret put TURSO_TOKEN    --project-name petsa
   npx wrangler pages secret put TURSO_URL      --project-name petsa   # libsql://petsa-….turso.io
   npx wrangler pages secret put ACCESS_TEAM    --project-name petsa   # <team>.cloudflareaccess.com
   npx wrangler pages secret put ACCESS_AUD     --project-name petsa   # from the Access application
   npx wrangler pages secret put ALLOWED_EMAILS --project-name petsa   # optional, comma-separated
   ```
5. In Zero Trust → Access → Applications, add a **self-hosted** application
   covering `petsa.pages.dev` **and** `*.petsa.pages.dev` (preview URLs), with
   an Allow policy for your email(s). Copy its **Application Audience (AUD)
   tag** into `ACCESS_AUD`.
6. Deploy again so the function picks up the settings.

## Notes

- When the Access session expires, the app's database calls fail until you
  reload the page and sign in again.
- To revoke access to the data, invalidate the production token in Turso.
  The development token in `.env.local` is separate.
- Tests: `cd web_proxy && npm test`
