# Security checklist — decide before you run pattern 07

Decide these first. The script does not decide them for you, and
"left at default" is an answer that must be written down, not assumed.

## Decide before you run

- [ ] Admin password: changed from the default? New password stored
      in the operator's credential store (never in a repo file)?
- [ ] Roles: which roles exist? Which role, if any, may read each
      workspace? (See `access-rules.properties` for the example set.)
- [ ] Public vs restricted: is any layer intentionally public? Name
      it here; every other layer gets a rule or is listed UNRULED.
- [ ] Network scope: localhost-only, tailnet-only, or wider?
      Wider than tailnet is an explicit operator decision — record
      the reason and the review date.
- [ ] WPS `Execute`: anonymous or authenticated-only? (Default
      recommendation: authenticated-only.)
- [ ] REST API: authenticated-only, always. Confirm no anonymous
      admin path exists.

## Leave locked down (do not open without a recorded decision)

- The REST API (`/rest/...`) to anonymous users.
- The admin web UI's privileged actions to anonymous users.
- The default admin credentials, on any node.
- WPS `Execute` to anonymous users, unless a public process is an
  explicit, recorded decision.
- Any service endpoint beyond the intended network scope
  (localhost / tailnet-only by default).

## After applying rules

- [ ] `bash inputs/audit-checks.sh` reports LOCKED for every
      endpoint you intended to close.
- [ ] Any OPEN result is either an intended-public endpoint (named
      above) or a failed run to fix — never an unexamined note.
- [ ] The new admin password is in the credential store and out of
      the shell environment (`unset NEW_ADMIN_PASSWORD`).
