# tools/

Both scripts drive a browser against a running ILIAS. Locally that is the ILIAS 11 Docker
stack on `http://localhost:8082` with this repository bind-mounted as
`public/Customizing/skin/LUH-Skin`. The login page is rendered with the **default** system
style, so the stack must have `skin = LUH-Skin`, `style = LUH-Style` in the `[layout]`
section of `public/data/<client>/client.ini.php`; pages behind the login follow the skin
chosen in the user's own settings.

Neither script is a dependency of the skin. Install the browser driver somewhere else and
point Node at it:

```bash
npm install --prefix /tmp/pt puppeteer-core   # uses the installed Google Chrome
export NODE_PATH=/tmp/pt/node_modules
```

The image has no dart-sass. Build on the host, in place (the skin sits inside a folder
that holds a copy of `templates/default` and `ilias_version.php` from the container), or
standalone with `./update-skin.sh prod "" /path/to/ilias-copy` — see
[Für die Implementierung](../README.md#-für-die-implementierung).

## `shoot.js` — review screenshots after a build or an ILIAS update

Logs in and captures the login page, the opened login form, dashboard, repository, an
administration page and the repository at phone width. It also reports every skin asset
that failed to load (a font or image answering 404 is invisible in a screenshot) and exits
with status 1 in that case.

```bash
ILIAS_PASSWORD=… node tools/shoot.js <output-dir>
```

The password is read from the environment only. Further variables: `ILIAS_URL` (default
`http://localhost:8082`), `ILIAS_USER` (default `root`), `CHROME_PATH`.

## `shoot-login.js` — regenerate the README login screenshot

The README embeds `screenshots/luh-skin-release_11-1.png`. A code change does **not**
update it automatically, and CI enforces this via the **Screenshot Guard** workflow:
a PR that touches the login SCSS/templates but not `screenshots/` fails (bypass with
`[skip-screenshot]` in the PR title when the rendered result is genuinely unchanged).

Regenerate it after any visual login change:

```bash
./update-skin.sh prod          # so localhost:8082 serves the current skin
node tools/shoot-login.js
```

The script compensates for two ways the local stack differs from production: it injects
the "Login mit WebSSO" option (there is no Shibboleth locally) and pins `<html lang>`, so
the capture does not depend on which language packs the local instance has installed.

`SHOOT_LANG` switches only the skin's bilingual blocks, not ILIAS's own strings —
`SHOOT_LANG=en` on a German instance gives an English login mask in a German page
frame. For a fully English capture, switch the instance language in ILIAS itself.

Overrides: `LOGIN_URL`, `OUT_PATH`, `SHOOT_LANG` (`de` default, `en` for the English
variant), `CHROME_PATH`.

## Cutting a release

Nothing to do by hand — releases are automated by release-please. Write commits as
Conventional Commits, and merging the **»chore(main): release x.y.z«** pull request it
keeps open on `main` creates the tag and the GitHub Release.

See [Release-Prozess](../README.md#-release-prozess) in the main README.
