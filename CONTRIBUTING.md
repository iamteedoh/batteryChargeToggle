# Contributing to batteryChargeToggle

Thanks for helping improve batteryChargeToggle. This guide covers local setup,
validation, and the pull request process.

## Ways to contribute

- **Report a bug** using the repository's bug report form.
- **Request a feature** using the feature request form.
- **Send a pull request** after opening an issue for non-trivial changes.
- **Report a vulnerability privately** by following [SECURITY.md](SECURITY.md).

## Prerequisites

- Bash and `awk` (present on any mainstream Linux distribution)
- ShellCheck
- gitleaks 8.30.1 or newer
- A Linux laptop with a sysfs battery interface
  (`/sys/class/power_supply/BAT0/`) only when exercising the script itself;
  charge threshold toggling additionally requires kernel-level threshold
  support and root privileges

## Set up from a clean clone

```bash
git clone https://github.com/iamteedoh/batteryChargeToggle.git
cd batteryChargeToggle
chmod +x battery-toggle.sh
```

Never commit `.env` files, tokens, credentials, or private infrastructure
details.

## Run the validation suite

Run the same checks that protect `main`:

```bash
git ls-files -z '*.sh' | xargs -0 shellcheck
git ls-files -z '*.sh' | xargs -0 -n1 bash -n
gitleaks git . --config .gitleaks.toml --redact --no-banner
```

When changing script behavior, exercise the affected mode locally where the
hardware allows it: `./battery-toggle.sh --status` is safe on any Linux
laptop, while a toggle run writes kernel charge thresholds and needs
compatible hardware plus root.

## Project layout

- `battery-toggle.sh` — the toggle and battery status report script
- `.github/workflows/` — source validation and source-only release automation

## Pull request process

1. Create a branch from `main`.
2. Make the smallest complete change and update documentation.
3. Run the full validation suite above.
4. Use a [Conventional Commit](https://www.conventionalcommits.org/) PR title:
   `feat:`, `fix:`, `docs:`, `refactor:`, `ci:`, `test:`, or `chore:`.
5. Complete the pull request template and link the related public issue.
6. Wait for all required checks to pass, then squash-merge.

The PR title becomes the squash commit subject and drives release-please:
`fix:` creates a patch release, `feat:` creates a minor release, and a `!` or
`BREAKING CHANGE:` footer creates a breaking release.

## License

By contributing, you agree that your contributions are licensed under the
project's [GNU General Public License v3](LICENSE).
