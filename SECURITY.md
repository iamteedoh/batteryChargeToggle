# Security Policy

## Reporting a vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private vulnerability reporting instead:

1. Open the repository's **Security** tab.
2. Select **Report a vulnerability**.
3. Provide the details requested below.

If private reporting is unavailable, contact the maintainer through the
[iamteedoh GitHub profile](https://github.com/iamteedoh).

## What to include

- A description of the issue and its potential impact
- Reproduction steps or a minimal proof of concept
- The affected release, commit, platform, and component
- A suggested remediation, if known

Never include live bearer tokens, passwords, SSH keys, private hostnames, or
unredacted logs in a report.

## Security-sensitive areas

batteryChargeToggle runs with root privileges and writes to kernel interfaces,
so the most sensitive surfaces are:

- The automatic privilege escalation (`exec sudo "$0" "$@"`) and any argument
  handling around it
- Writes to sysfs charge threshold files under `/sys/class/power_supply/`
- The `BAT` path construction and files read from sysfs
- Battery values read from sysfs and interpolated into `awk` expressions
- CI and release automation workflows

## Supported versions

Security fixes land on `main` and ship in the next tagged source release. Test
against the latest release or `main` before reporting an issue.
