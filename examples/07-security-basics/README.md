# 07 — Security basics: admin credentials, service-level access rules, and what to leave locked down

> Status: **design-only draft — not run, not runtime-validated.**
> Nothing in this pattern claims a run, a validation, or an end-to-end
> deployment. Security settings are site decisions: this pattern
> shows the mechanisms and the checks, and flags every choice that
> is the operator's call rather than prescribing it.

## What it demonstrates

Three things, in order:

1. **Admin credential handling:** changing the default admin
   password through the REST API, with the new password supplied
   only via environment variable — never written into a file,
   a script, or a shell history entry you keep.
2. **Service-level access rules:** data access rules that grant
   read access per workspace/layer and role, applied through the
   REST API, using `inputs/access-rules.properties` as the example
   rule set.
3. **What to leave locked down:** the checklist in
   `inputs/security-checklist.md` — WPS and the REST API not left
   open to anonymous users, the admin UI not exposed beyond the
   intended network scope, and default credentials gone — plus
   audit checks (`inputs/audit-checks.sh`) that prove each item.

## Prerequisites + versions

- GeoServer 3.0.2 on Node-1 (per seed); Node-4 migrated to 3.0.2
  (2026-10-25). Node-3's current version: **to confirm at validation**.
- Java 21 runtime for GeoServer 3.x. Default GeoServer port 8080.
- An admin account you control, and a decision (yours, not this
  pattern's) on: which roles exist, which layers are public vs
  restricted, and what network scope the server binds to
  (localhost or tailnet-only is the default recommendation here;
  anything wider is an explicit operator decision to record).
- `curl` and `python3` (standard library only). The Python helper safely JSON-encodes credentials and writes a mode-0600 temporary payload; credentials remain environment-only. Credentials only as placeholders:
  `<GEOSERVER_URL>`, `<ADMIN_USER>`, `<ADMIN_PASSWORD>`,
  `<NEW_ADMIN_PASSWORD>`. The new password is read from the
  environment at run time and is never echoed by the script.

## Steps

1. Read `inputs/security-checklist.md` first and decide the role
   and scope answers it asks for. Do not run the script until the
   "decide before you run" items have answers.
2. Apply the rules:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   export NEW_ADMIN_PASSWORD='<NEW_ADMIN_PASSWORD>'
   bash apply-access-rules.sh
   ```
   The script changes the admin password, applies the example
   data access rules, and then re-authenticates with the new
   password to confirm the change took effect. After it runs,
   update your own credential store with the new password and
   discard the shell session's environment.
3. Run the audit checks:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   bash inputs/audit-checks.sh
   ```
   It probes, without credentials, the endpoints that should be
   closed, and reports each as LOCKED or OPEN.

## Expected output

- The password change returns HTTP 200 and re-authentication
  with the new password succeeds; the old password then returns
  HTTP 401 (the script checks this).
- The access-rule update returns HTTP 200, and a subsequent
  `GET` of the rules returns the applied rule set.
- The audit script reports LOCKED for: the REST API without
  credentials, the admin web UI's privileged actions without
  credentials, and (if you chose to restrict it) WPS `Execute`
  without credentials. Any OPEN result is listed explicitly —
  an OPEN result on an endpoint you intended to lock is a failed
  run, not a note.

## Failure behavior

- **Invalid input:** a malformed rules file, or a rule naming a
  workspace/layer that does not exist, is rejected (HTTP 400) and
  the script stops before the password change — order matters:
  rules are validated first so a failed run never leaves you
  locked out with a changed password and unapplied rules. If
  the password change itself fails, the script stops and the old
  credentials remain in effect; do not retry blindly — confirm
  which password is current before the next attempt.
- **No-result case:** if no access rules are defined for a layer,
  GeoServer's default behavior applies (readable per the default
  data rules). "No rule" is not "locked down": the audit script
  treats any layer with no rule as UNRULED and lists it, so an
  operator cannot mistake an absent rule for a deny.
- **Lockout risk:** changing the admin password is the one step
  in this cookbook that can lock the operator out. Run it only
  with a working credential store update ready, and only after
  the rules step has succeeded. If lockout happens, recovery is
  a server-side admin action outside this pattern — it is not
  scripted here, deliberately.

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed. No node, tool run, or output is
cited as evidence, because none exists yet.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run of
`apply-access-rules.sh` plus `inputs/audit-checks.sh` against a
named node and GeoServer version (GeoServer 3.0.2 on Node-1 first;
Node-3's version to confirm at validation), with: the script's
full output (password values redacted — the run record must never
contain a real password), the retrieved rule set, the audit
results showing LOCKED for each intended-closed endpoint, and the
failure checks above (malformed rules, unruled layer listed as
UNRULED, old password rejected after change). Until that run
record exists, this pattern stays design-only.
