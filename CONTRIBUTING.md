# Contributing to Blankly

Thanks for helping! Blankly is a small macOS app: `main.swift` is the app, `FinderExtension.swift` is the Finder extension, `build.sh` builds everything with `swiftc` (no Xcode project).

## Sending a pull request

1. Fork the repository (or, if you were given write access, create a branch in it). Never push to `main` directly.
2. Build and try your change by hand:
   ```bash
   zsh build.sh --no-install   # build/Blankly.app, .zip and .dmg — nothing is installed
   ```
   Ideas are welcome too — open a PR with a rough version, or start a thread in [Discussions](../../discussions).
3. Open a pull request into `main` and fill in the template. Keep it focused: one change per PR.
4. **CI must be green.** Pull requests are built on a macOS runner (`build` workflow) and checked by the other workflows in `.github/workflows`. Fix red checks before asking for review.

**Releases are made by the maintainer only.** Please don't change the version in `build.sh` or touch `release.sh` unless that is the point of the PR; the maintainer bumps the version when releasing.

Bugs: use the [bug report form](../../issues/new/choose). Ideas and questions: [Discussions](../../discussions).

## Code signing (maintainers)

By default `build.sh` signs ad-hoc (no Apple account needed). Releases can instead be signed with a **Developer ID Application** certificate and notarized by Apple. This is done by the **release-build** workflow (`.github/workflows/release-build.yml`, started by hand: Actions → release-build → Run workflow, optional version). The signing logic lives in [`sign.sh`](sign.sh).

If the secrets below are missing, the workflow still works and produces an ad-hoc build, so nothing breaks for forks and contributors.

### Secrets

| Secret | What it is |
|---|---|
| `MACOS_CERT_P12_BASE64` | The Developer ID Application certificate with its private key, exported as `.p12`, base64 |
| `MACOS_CERT_PASSWORD` | The password you set when exporting the `.p12` |
| `APPLE_TEAM_ID` | 10-character Team ID (developer.apple.com → Membership details) |
| `NOTARY_KEY_P8_BASE64` | App Store Connect API key (`AuthKey_XXXX.p8`), base64 |
| `NOTARY_KEY_ID` | The key's ID (10 characters) |
| `NOTARY_ISSUER_ID` | The Issuer ID (a UUID, shown above the keys list) |

Secret values are never printed by the scripts; keep it that way.

### How to get them (needs a paid Apple Developer membership)

**Developer ID Application certificate** (only the Account Holder can create Developer ID certificates):

1. On a Mac: Keychain Access → Certificate Assistant → *Request a Certificate From a Certificate Authority…* → your email, a name, *Saved to disk*. This makes a `.certSigningRequest` (CSR) and a private key in your keychain.
2. [developer.apple.com](https://developer.apple.com/account) → Certificates, Identifiers & Profiles → Certificates → **+** → *Developer ID Application* → upload the CSR → download the `.cer`.
3. Double-click the `.cer` to add it to Keychain Access (it must sit next to its private key, in *My Certificates*).
4. Right-click the certificate → *Export…* → format `.p12`, set a password (this is `MACOS_CERT_PASSWORD`).
5. Encode it: `base64 -i DeveloperID.p12 | pbcopy` — paste into `MACOS_CERT_P12_BASE64`. Then delete the `.p12` from disk.

**App Store Connect API key** (for notarization):

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users and Access → Integrations → *App Store Connect API* → **+**. Name: `Blankly CI`, access: **Developer**.
2. Note the **Key ID** and the **Issuer ID**; download the `AuthKey_XXXX.p8` — Apple lets you download it **once**.
3. `base64 -i AuthKey_XXXX.p8 | pbcopy` → `NOTARY_KEY_P8_BASE64`. Delete the `.p8` afterwards.

### Where the secrets go

Repository secrets: Settings → Secrets and variables → Actions → *New repository secret*. On a personal repository only the owner can manage secrets — collaborators with *Write* access can run workflows but cannot add or read secrets. So there are two ways:

- **The owner adds them.** The certificate holder sends the values to the owner over a safe channel (a password manager's share, or an encrypted file — not plain chat). The owner pastes them into the repository secrets.
- **The certificate holder builds in their own fork.** They put the secrets into *their fork's* settings, run **release-build** there (Actions tab of the fork), and the owner takes the result: `zsh release.sh --from-ci <run-id> --ci-repo <their-login>/blankly --notes "…"`. The owner's repository never holds the certificate.

(Giving the certificate holder the *Admin* role on the repository would let them add secrets themselves, but it also gives much more than needed.)

### Publishing a signed release

1. Run **release-build** and wait for it to finish (it uploads `Blankly.zip` and `Blankly-x.y.dmg` as the `Blankly` artifact).
2. On the maintainer's Mac, which holds the Sparkle key:
   ```bash
   zsh release.sh --from-ci <run-id> --notes "What's new" --notes-ru "Что нового"
   ```
   It downloads the artifacts, signs `Blankly.zip` with the Sparkle (EdDSA) key, writes `appcast.xml` and creates the GitHub release. Without `--from-ci` it builds locally, ad-hoc, as before.

### Updating from an ad-hoc version

Sparkle accepts an update when the archive's EdDSA signature matches the `SUPublicEDKey` of the installed app; a change of the code-signing identity is allowed in that case. So users of the ad-hoc versions update to the Developer ID build normally. Because macOS ties permissions to the signing identity, they may once be asked again to let Blankly control Finder, and may need to re-enable the Finder extension (Settings → *Turn On…*). Keep the Sparkle key and `SUPublicEDKey` unchanged.
