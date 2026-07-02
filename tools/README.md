# tools/

## `shoot-login.js` — regenerate the README login screenshot

The README embeds `screenshots/luh-skin-release_10-1.png`. A code change does **not**
update it automatically, and CI enforces this via the **Screenshot Guard** workflow:
a PR that touches the login SCSS/templates but not `screenshots/` fails (bypass with
`[skip-screenshot]` in the PR title when the rendered result is genuinely unchanged).

Regenerate it after any visual login change:

```bash
# 1. Start the ILIAS 10 test stack and compile the skin so localhost:8081 is current
cd ../../../../..   # repo lives at ilias10/public/Customizing/skin/luh in dev
docker compose -f ilias10/docker-compose.yml up -d
( cd ilias10/public/Customizing/skin/luh && ./update-skin.sh prod "" /path/to/ilias-root )

# 2. Capture (injects the production "Login mit WebSSO" option, which the local
#    Shibboleth-less instance does not render on its own)
cd ilias10/public/Customizing/skin/luh
npx puppeteer@24 --yes node tools/shoot-login.js
```

Overrides: `LOGIN_URL`, `OUT_PATH`, `CHROME_PATH` (path to a Chrome binary if you do
not want puppeteer's bundled Chromium).

## Cutting a release

1. Land your changes on `main` (via PR from `release_*`).
2. Bump the version in `README.md` and promote `CHANGELOG.md`'s `[Unreleased]`
   section to `[x.y.z]` with today's date.
3. Tag and push — the **Release** workflow publishes the GitHub Release from the
   matching CHANGELOG section automatically:

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
   ```
