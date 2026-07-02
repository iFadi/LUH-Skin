# Changelog

## [2.2.0](https://github.com/iFadi/LUH-Skin/compare/v2.1.3...v2.2.0) (2026-07-02)

### Features

* **registration:** ship the ILIAS registration core modification as a small,
  version-pinned unified diff (`components/ILIAS/Registration/luh-username-rule.patch`)
  instead of a full 27 KB copy of the core class. The patch is applied idempotently by
  the deploy tooling and **fails loudly** if ILIAS changes the patched region, instead
  of silently reverting upstream fixes. Adds `PINNED_ILIAS_VERSION` and a
  **Registration Patch Guard** CI workflow that verifies the patch still applies to the
  pinned ILIAS release and stays purely additive.

### ⚠ BREAKING CHANGES

* **registration:** the full-copy `class.ilAccountRegistrationGUI.php` was removed.
  Apply the patch instead (see `components/ILIAS/Registration/README.md` or the
  `apply_luh_registration_patch.sh` deploy script).


## [2.1.3](https://github.com/iFadi/LUH-Skin/compare/v2.1.2...v2.1.3) (2026-07-02)

### Bug Fixes

* **login:** stop the login page from leaking raw markup and a duplicated "Login mit
  WebSSO". The explanatory HTML comment contained the `{SHIB_LOGIN_FORM}` token;
  ILIAS expands template tokens even inside comments, and the injected Shibboleth
  form (which itself contains `-->`) terminated the comment early. Reworded the
  comment so it no longer contains the token.


## [2.1.2](https://github.com/iFadi/LUH-Skin/compare/v2.1.1...v2.1.2) (2026-07-02)

### Bug Fixes

* **login:** the "Hinweise" links now signal their real behaviour — an "opens in new
  tab" arrow (↗) on the external Erstanmeldung / Hinweise zum Login links and a
  navigation chevron (❯) on Selbstregistrierung, replacing the ▷ that wrongly implied
  an accordion/expand; the two external links also announce "öffnet in neuem Tab" to
  screen readers (`title` + `aria-label`)
* **login:** the "für Angehörige der LUH" subtitle now lives inside the Shibboleth
  block, so it renders only together with the "Login mit WebSSO" link — no orphaned
  subtitle (and no stray gap) when WebSSO is inactive

### Miscellaneous

* **login:** WebSSO subtitle changed from "für Studierende und Lehrende" to
  "für Angehörige der LUH"


## [2.1.0](https://github.com/iFadi/LUH-Skin/compare/v2.0.0...v2.1.0) (2026-06-09)

### Features

* **login:** redesign the login page as a two-column card — left column with
  "Login mit WebSSO" / "Login ohne WebSSO" text links and descriptions, right
  column "Hinweise" with button-style links (Erstanmeldung, Hinweise zum Login,
  Selbstregistrierung); Gasthörende folded into the "ohne WebSSO" description
* **login:** WebSSO link (Shibboleth) now reads "Login mit WebSSO"


## [2.0.0](https://github.com/iFadi/LUH-Skin/compare/v1.3.0...v2.0.0) (2026-06-08)

ILIAS 10 compatibility release. **This version targets ILIAS 10.x and is not compatible with
ILIAS 9.** The ILIAS 9 line continues on the `v1.x` tags.


### ⚠ BREAKING CHANGES

* **skin location:** ILIAS 10 moved custom skins from `public/Customizing/global/skin/` to
  `public/Customizing/skin/` (the `global` segment was dropped). Install the skin under the new path.
* **template overrides:** all overridden template paths were migrated from `Services/<X>/` to
  `components/ILIAS/<X>/` to match the ILIAS 10 component restructure (Init, Mail, Registration).

### Features

* **build:** verify the delos `@use` import resolves under ILIAS 10 (unchanged 6 levels —
  `templates/` stays at the ILIAS root while `Customizing` moved under `public/`); all
  overridden delos variables verified present in ILIAS 10
* **build:** `update-skin.sh` can now compile outside an ILIAS install via `$ILIAS_ROOT`/3rd arg
* **docker:** ILIAS 10.8 test stack (`srsolutions/ilias:10.8-php8.3-apache`) with auto-selected LUH skin

### Bug Fixes

* **assets:** point fonts/icons at the ILIAS 10 web path `/assets/fonts/` (was
  `/templates/default/fonts/`, the ILIAS 9 location, which 404s under the new `public/` docroot)
* **scss:** replace the deprecated global `darken()` with `color.adjust()`
* **registration:** re-derive the `ilAccountRegistrationGUI` core patch from the pristine ILIAS 10
  class so the only delta is the LUH `XXX-XXX` username rule; prevents silently reverting upstream
  fixes. The CSS (`LUH-Style.css`) **must be recompiled** against ILIAS 10's delos via `update-skin.sh`.


## [1.3.0](https://github.com/iFadi/LUH-Skin/compare/v1.2.0...v1.3.0) (2026-04-24)


### Features

* **login:** add Gasthörende notice with inline Stud.IP link above the secondary login buttons
* **login:** add Stud.IP Login button alongside ILIAS Login for direct access to Stud.IP SSO


## [1.2.0](https://github.com/iFadi/LUH-Skin/compare/v1.1.1...v1.2.0) (2026-04-24)


### Features

* **login:** promote WebSSO as primary login method; demote ILIAS login to a secondary collapsed state
* **login:** add branded badge ("Studierende & Lehrende") above WebSSO button
* **login:** add descriptive hint text below WebSSO button
* **login:** introduce full-width divider between primary and secondary login sections
* **login:** add second divider above "Hinweise zum Login" for visual grouping
* **login:** center badge, WebSSO button and hint text within the card
* **login:** add fully responsive layout with tablet (≤ 720 px) and mobile (≤ 520 px) breakpoints; secondary items stack in a single column on small screens


### Bug Fixes

* **security:** remove external jQuery CDN dependency from login template; use ILIAS-bundled context via vanilla JS instead
* **login:** replace inline `style=""` attributes with semantic CSS classes throughout the login template
* **login:** replace `display:none` toggle with `hidden` attribute for accessible show/hide of the ILIAS login form
* **login:** add `aria-expanded`, `aria-controls` and `rel="noopener noreferrer"` attributes for accessibility and security on external links
* **login:** remove Nutzungsvereinbarung (user agreement) block from login page
* **login:** suppress ILIAS base-theme border on Shibboleth form via targeted `!important` overrides on all `.form-horizontal` selectors inside `#luhLogin`
* **login:** widen WebSSO button to 300 px with 18 px font and increased padding for better touch-target size


## [1.1.1](https://github.com/iFadi/LUH-Skin/compare/v1.1.0...v1.1.1) (2025-07-30)


### Bug Fixes

* path for dev env ([d5d22ab](https://github.com/iFadi/LUH-Skin/commit/d5d22abda22687284c3c46a11a91cc4fbe1244a7))
* refactor update script ([a9a0e22](https://github.com/iFadi/LUH-Skin/commit/a9a0e22e755d2bc96f3286d330450870586298c7))

## [1.1.0](https://github.com/iFadi/LUH-Skin/compare/v1.0.7...v1.1.0) (2025-05-14)


### Features

* initial release for ilias 9 ([f52d91f](https://github.com/iFadi/LUH-Skin/commit/f52d91f4817a9f1ae211eb545d4fd2b13873f188))


### Bug Fixes

* changed footer color, fixed white box issue in magazin ([27b77e3](https://github.com/iFadi/LUH-Skin/commit/27b77e37710479663f7fe5fe695fe8c4ceacafc3))
* colors style ([17925e7](https://github.com/iFadi/LUH-Skin/commit/17925e7c7654b4b0bac5b160a546ed7703ad6ff2))
* hotfix ([cc4377c](https://github.com/iFadi/LUH-Skin/commit/cc4377cda65b7a9086bd38d639c16b80093d9141))
* hotfix 2 ([52b8aba](https://github.com/iFadi/LUH-Skin/commit/52b8aba31aa897ed459e4eacad88ba686c6e37ba))
* update colors ([d386409](https://github.com/iFadi/LUH-Skin/commit/d3864097abbaaa0279bcfd4fc55c7d4da153930a))
* update LUH colors ([3b07ce5](https://github.com/iFadi/LUH-Skin/commit/3b07ce55ff146c9478dfe59c8c272dbb2f71d6c6))

## [1.0.7](https://github.com/iFadi/LUH-Skin/compare/v1.0.6...v1.0.7) (2024-10-21)


### Bug Fixes

* compile skin for ILIAS v8.15 ([20fe6a5](https://github.com/iFadi/LUH-Skin/commit/20fe6a5bc19eec47b924969c8358d6c5e1a51750))

## [1.0.6](https://github.com/iFadi/LUH-Skin/compare/v1.0.5...v1.0.6) (2024-03-26)


### Bug Fixes

* add screenshot ([2650393](https://github.com/iFadi/LUH-Skin/commit/2650393e951fbf3f5714ba68d7e284602df0ac51))
* added action workflow for releases ([f6e961a](https://github.com/iFadi/LUH-Skin/commit/f6e961a4f4e1b914d410876b804247ca2fd1b8cd))
* added custom breadcrumb ([d8a8291](https://github.com/iFadi/LUH-Skin/commit/d8a82913b15f93972b76f6657e1b394b9c322915))
* added LUH background image ([53266c8](https://github.com/iFadi/LUH-Skin/commit/53266c8cb54582efa81cefad06740ceab2841126))
* added missing js ([6015093](https://github.com/iFadi/LUH-Skin/commit/60150936ad6e8d461340669dd2ab259077c3bbf1))
* added update script ([bc5f3ca](https://github.com/iFadi/LUH-Skin/commit/bc5f3ca41e7e17e285da21034ccabf4a974b2812))
* complie less for release ([d35cf78](https://github.com/iFadi/LUH-Skin/commit/d35cf78beebe779f2b0a40d939b0f9cb2c542ee9))
* custom login page with shib ([3212ddc](https://github.com/iFadi/LUH-Skin/commit/3212ddcf2013cebcb50972df7112da8360e1d233))
* custom mainbar ([1950a00](https://github.com/iFadi/LUH-Skin/commit/1950a0008cd361754642d7fb802475ca5be9bdf2))
* custom template for mail notification ([eee6229](https://github.com/iFadi/LUH-Skin/commit/eee62290b13221ca4e2b2580738036c727bef322))
* customized footer ([3aad486](https://github.com/iFadi/LUH-Skin/commit/3aad4868f0549a1047053fad2660093515d1b2e3))
* customized header and added logos ([deea552](https://github.com/iFadi/LUH-Skin/commit/deea5526890890a27e23bfa1fd46375189556858))
* LUH-ID Selbstregistrierung check ([2fc12e3](https://github.com/iFadi/LUH-Skin/commit/2fc12e3c4e6921bd14cf48c842657d1a26559820))
* update ilAccountRegistrationGUI to ILIAS 8.9 ([a10e23d](https://github.com/iFadi/LUH-Skin/commit/a10e23d9eb647ad7907b449a0012226dbfce98bc))
* update login page ([b53c8cd](https://github.com/iFadi/LUH-Skin/commit/b53c8cd4f69d43b2b469327179d35aa5e5ffb6ac))
* update mainbar ([b57debf](https://github.com/iFadi/LUH-Skin/commit/b57debf0913e6d70aefe211d3ef4f2767b245979))
* Update README ([b351b41](https://github.com/iFadi/LUH-Skin/commit/b351b41ad68302a5bf7f5e634fbf4beb31ccde9e))
* update to ILIAS 8.9 ([4fb3352](https://github.com/iFadi/LUH-Skin/commit/4fb33528602ecb3fcece876542b6bdbad392513a))

## [1.0.5](https://github.com/iFadi/LUH-Skin/compare/v1.0.4...v1.0.5) (2024-03-26)


### Bug Fixes

* complie less for release ([d35cf78](https://github.com/iFadi/LUH-Skin/commit/d35cf78beebe779f2b0a40d939b0f9cb2c542ee9))
* LUH-ID Selbstregistrierung check ([2fc12e3](https://github.com/iFadi/LUH-Skin/commit/2fc12e3c4e6921bd14cf48c842657d1a26559820))
* update ilAccountRegistrationGUI to ILIAS 8.9 ([a10e23d](https://github.com/iFadi/LUH-Skin/commit/a10e23d9eb647ad7907b449a0012226dbfce98bc))

## [1.0.4](https://github.com/iFadi/LUH-Skin/compare/v1.0.3...v1.0.4) (2024-02-22)


### Bug Fixes

* update mainbar ([b57debf](https://github.com/iFadi/LUH-Skin/commit/b57debf0913e6d70aefe211d3ef4f2767b245979))

## [1.0.3](https://github.com/iFadi/LUH-Skin/compare/v1.0.2...v1.0.3) (2024-02-22)


### Bug Fixes

* update login page ([b53c8cd](https://github.com/iFadi/LUH-Skin/commit/b53c8cd4f69d43b2b469327179d35aa5e5ffb6ac))
* update to ILIAS 8.9 ([4fb3352](https://github.com/iFadi/LUH-Skin/commit/4fb33528602ecb3fcece876542b6bdbad392513a))

## [1.0.2](https://github.com/iFadi/LUH-Skin/compare/v1.0.1...v1.0.2) (2024-02-22)


### Bug Fixes

* added missing js ([6015093](https://github.com/iFadi/LUH-Skin/commit/60150936ad6e8d461340669dd2ab259077c3bbf1))

## [1.0.1](https://github.com/iFadi/LUH-Skin/compare/v1.0.0...v1.0.1) (2024-02-22)


### Bug Fixes

* add screenshot ([2650393](https://github.com/iFadi/LUH-Skin/commit/2650393e951fbf3f5714ba68d7e284602df0ac51))
* custom login page with shib ([3212ddc](https://github.com/iFadi/LUH-Skin/commit/3212ddcf2013cebcb50972df7112da8360e1d233))

## 1.0.0 (2024-02-22)


### Bug Fixes

* added action workflow for releases ([f6e961a](https://github.com/iFadi/LUH-Skin/commit/f6e961a4f4e1b914d410876b804247ca2fd1b8cd))
* added custom breadcrumb ([d8a8291](https://github.com/iFadi/LUH-Skin/commit/d8a82913b15f93972b76f6657e1b394b9c322915))
* added LUH background image ([53266c8](https://github.com/iFadi/LUH-Skin/commit/53266c8cb54582efa81cefad06740ceab2841126))
* added update script ([bc5f3ca](https://github.com/iFadi/LUH-Skin/commit/bc5f3ca41e7e17e285da21034ccabf4a974b2812))
* custom mainbar ([1950a00](https://github.com/iFadi/LUH-Skin/commit/1950a0008cd361754642d7fb802475ca5be9bdf2))
* custom template for mail notification ([eee6229](https://github.com/iFadi/LUH-Skin/commit/eee62290b13221ca4e2b2580738036c727bef322))
* customized footer ([3aad486](https://github.com/iFadi/LUH-Skin/commit/3aad4868f0549a1047053fad2660093515d1b2e3))
* customized header and added logos ([deea552](https://github.com/iFadi/LUH-Skin/commit/deea5526890890a27e23bfa1fd46375189556858))
* Update README ([b351b41](https://github.com/iFadi/LUH-Skin/commit/b351b41ad68302a5bf7f5e634fbf4beb31ccde9e))
