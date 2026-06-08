# Registration core patch (`class.ilAccountRegistrationGUI.php`)

⚠️ **This is NOT a skin template override — it is a patch of an ILIAS core class.**

ILIAS does not expose a hook for the self-registration username validation, so the LUH
rule (reject usernames in `XXX-XXX` format, which are reserved for LUH-IDs / WebSSO) is
applied by overwriting the core class. The file in this folder is the **pristine ILIAS 10
core class plus exactly one added validation block** (search for `LUH customization`).

## Installation

Copy the file over the ILIAS 10 core class. From this directory:

```bash
cp class.ilAccountRegistrationGUI.php ../../../../../../components/ILIAS/Registration/classes/
```

(Path assumes the skin lives at `public/Customizing/skin/luh/` and ILIAS core at
`public/components/ILIAS/Registration/classes/`.)

## ⚠️ Maintenance on every ILIAS update

This file **must be re-derived from core on every ILIAS minor/major update**, otherwise
copying a stale class would silently revert upstream fixes. To re-derive:

1. Take the new pristine `components/ILIAS/Registration/classes/class.ilAccountRegistrationGUI.php`
   from the target ILIAS release.
2. Re-insert only the `// LUH customization:` block (the `XXX-XXX` `preg_match` check) right
   after the `ilUtil::isLogin($login)` validation in `register()`.
3. Verify with `diff` that the file differs from pristine core by **only** the LUH block.
