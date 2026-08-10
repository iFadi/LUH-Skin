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

# 2. Capture. The script compensates for two ways the local stack differs from
#    production: it injects the "Login mit WebSSO" option (no Shibboleth locally)
#    and pins <html lang> so the capture does not depend on which language packs
#    the local instance happens to have installed.
cd ilias10/public/Customizing/skin/luh
node tools/shoot-login.js
```

`SHOOT_LANG` switches only the skin's bilingual blocks, not ILIAS's own strings —
`SHOOT_LANG=en` on a German instance gives an English login mask in a German page
frame. For a fully English capture, switch the instance language in ILIAS itself.

The script needs puppeteer resolvable from `require`. With no `node_modules` in this
repo, install it somewhere and point Node at it:

```bash
npm install puppeteer@24 --prefix /tmp/pt
NODE_PATH=/tmp/pt/node_modules node tools/shoot-login.js
```

Overrides: `LOGIN_URL`, `OUT_PATH`, `SHOOT_LANG` (`de` default, `en` for the English
variant), `CHROME_PATH` (path to a Chrome binary if you do not want puppeteer's
bundled Chromium).

## Cutting a release

Nothing to do by hand — releases are automated by release-please. Write commits as
Conventional Commits, and merging the **»chore(main): release x.y.z«** pull request it
keeps open on `main` creates the tag and the GitHub Release.

See [Release-Prozess](../README.md#-release-prozess) in the main README.
