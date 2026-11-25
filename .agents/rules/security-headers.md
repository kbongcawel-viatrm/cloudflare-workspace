# Security headers — MUST standard

Every HTTP response served on `*.home-security.uk` (Workers, static assets,
proxied apps, error pages) MUST carry this header set. This is a hard
requirement, not a guideline — verify on deploy and after any header-layer
change (Worker code, transform rules, page rules).

## Required headers

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; upgrade-insecure-requests;
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), camera=(), microphone=()
```

## Rationale (do not remove)

1. **HSTS** — prevents MitM tampering and SSL-strip; `preload` pins the domain
   into browser HSTS lists.
2. **CSP** — primary XSS/injection defense; `object-src 'none'` +
   `frame-ancestors 'none'` + `base-uri 'self'` close the classic holes.
   Stricter variants are allowed (e.g. `script-src 'none'` on static pages);
   never loosen below this baseline.
3. **nosniff** — prevents MIME-sniffing script execution.
4. **X-Frame-Options: DENY** — legacy clickjacking protection backing up
   CSP `frame-ancestors`.
5. **COOP + CORP `same-origin`** — cross-origin isolation; prevents
   unauthorized embedding and cross-origin window/resource access.
6. **Referrer-Policy** — limits sensitive URL data leakage to third parties.
7. **Permissions-Policy** — disables unused powerful browser features.

## Workers.dev must stay disabled

`<worker>.<subdomain>.workers.dev` bypasses ALL zone controls — WAF, Access,
transform rules, geo-fencing. Every Worker's `workers.dev` subdomain AND
preview URLs MUST remain disabled (`subdomain.enabled=false`,
`previews_enabled=false`). Verify after any Worker deploy:

```bash
curl -s -o /dev/null -w "%{http_code}" https://<worker>.<acct-subdomain>.workers.dev/
# expect 404
```

## Rules

- Headers may be set by the Worker response, a Response Header Transform
  rule, or both — but the final response MUST contain all of the above.
- Stricter values are acceptable (e.g. `Referrer-Policy: no-referrer`,
  `script-src 'none'`); weaker values are NOT.
- `Cross-Origin-Embedder-Policy` is intentionally absent — `require-corp`
  would break legitimate cross-origin subresources (e.g. remote avatar
  images); only add it if all subresources are same-origin or CORP-enabled.
- Known acceptable deviations: `Permissions-Policy` may list additional
  disabled features; `Cache-Control` is per-resource and not part of this
  standard.
- Verify with `curl -sI https://<host>/` after every deploy that touches
  headers, and record the check in the session notes.
