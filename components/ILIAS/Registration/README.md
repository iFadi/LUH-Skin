# Registration core patch (`luh-username-rule.patch`)

⚠️ **This is NOT a skin template override — it is a patch of an ILIAS core class**
(`components/ILIAS/Registration/classes/class.ilAccountRegistrationGUI.php`).

ILIAS exposes no hook for self-registration username validation, so the LUH rule
(reject usernames in `XXX-XXX` format, reserved for LUH-IDs / WebSSO) is added by
patching the core class. Instead of shipping a full copy of the class, this folder
ships a **small, version-pinned unified diff** — the LUH block only. That makes the
change reviewable and, crucially, makes ILIAS drift **fail loudly** instead of
silently reverting upstream fixes.

- `luh-username-rule.patch` — the diff (purely additive: the `XXX-XXX` check).
- `PINNED_ILIAS_VERSION` — the ILIAS tag the patch was derived against (e.g. `v10.8`).

## Applying it

Use the deploy script — it detects the service user, honours the proxy, applies the
patch idempotently and aborts cleanly if it no longer applies:

```
server-administrator-scripts › ILIAS Update Scripts › apply_luh_registration_patch.sh
```

Manual equivalent, from the ILIAS root:

```bash
# check first (never touches core on failure), then apply
git apply --check "public/Customizing/skin/LUH-Skin/components/ILIAS/Registration/luh-username-rule.patch"
git apply         "public/Customizing/skin/LUH-Skin/components/ILIAS/Registration/luh-username-rule.patch"
# or with plain patch:  patch -p1 -i <patch>
```

Applying is idempotent: if it is already applied, the deploy script detects it
(reverse-apply check) and skips.

## Maintenance on ILIAS updates

You no longer re-derive on *every* update — only when ILIAS actually changes the
patched region:

- For most minor updates the surrounding code is unchanged, so the patch applies
  cleanly with no work.
- When ILIAS refactors `register()`, the apply **fails with a conflict and leaves
  core untouched**. That is the signal to re-derive:
  1. Bump `PINNED_ILIAS_VERSION` to the new ILIAS tag.
  2. Fetch that tag's pristine class, re-insert the `LUH customization` block after the
     `ilUtil::isLogin($login)` check, and regenerate the diff:
     ```bash
     diff -u pristine.php patched.php \
       | sed -e '1s|.*|--- a/components/ILIAS/Registration/classes/class.ilAccountRegistrationGUI.php|' \
             -e '2s|.*|+++ b/components/ILIAS/Registration/classes/class.ilAccountRegistrationGUI.php|' \
       > luh-username-rule.patch
     ```
- The **Registration Patch Guard** CI workflow fetches the pinned ILIAS class on every
  PR and fails if the patch no longer applies (or stops being purely additive), so you
  find out at review time — not on the production server.
