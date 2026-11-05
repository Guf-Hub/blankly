# AGENTS.md

Rules for AI coding agents (and humans) working on Blankly. What the app does: [README.md](README.md). How to send a PR: [CONTRIBUTING.md](CONTRIBUTING.md).

## Project shape

- Native macOS app in Swift/AppKit, macOS 13+, no Xcode project and no SwiftPM: `build.sh` calls `swiftc` directly. The only dependency is Sparkle (downloaded into `.vendor/` by `build.sh`).
- Two targets:
  - App: `main.swift Core.swift Formats.swift FormatOrder.swift Languages.swift`.
  - Finder extension (sandboxed): `FinderExtension.swift Formats.swift FormatOrder.swift Languages.swift`. It cannot use anything from `main.swift` or `Core.swift`.
- Code needed by both targets goes into a small shared file, preferably as `static` members of an `enum` (see `FormatList`, `FormatPrefs`).
- A new `.swift` file must be added to the right `swiftc` line(s) in `build.sh` **and** to `test.sh`.

## Before opening a PR

```bash
zsh test.sh                # unit checks, ends with "OK: …" (exit code 1 on failure)
zsh build.sh --no-install  # full universal build into build/, installs nothing
```

CI runs both (`test` and `build`) on every PR; `main` only accepts PRs with both green.

## Rules

- **Strings:** every UI string lives in `translations` in `Core.swift` (app) or `FinderSync.strings` in `FinderExtension.swift` (extension) and must exist in all 7 languages: en, ru, de, fr, es, zh-Hans, ja. `Tests/StringsTests.swift` fails otherwise.
- Product names are not translated: Word, Excel, PowerPoint, LibreOffice Writer/Calc/Impress, Markdown, JSON, etc.
- **Formats:** the built-in list is `FormatList.groups` in `Formats.swift`. A new format also needs a starter file (`Resources/templates/empty.<ext>`) described in `Tests/TemplatesTests.swift`) or an entry in `starterText` in `main.swift` if an empty file is not a valid document.
- Settings live in `UserDefaults` domain `app.blankly`; the Finder extension reads them read-only. Don't rename existing keys: installed users would lose their settings.
- Keep the menu short. Ask before adding new menu items or settings.
- **Don't** change `VERSION` in `build.sh`, `release.sh`, `sign.sh` or `.github/workflows/release-build.yml` unless the task is about them; releases are made by the maintainer.
- **Don't** download release assets (`Blankly.dmg`, `Blankly.zip`) to check them: every download counts in the README "installs" badge. Use the GitHub API `digest` field instead.
- Never commit secrets or signing material (`*.p12`, `*.p8`, keys). Signing secrets live only in GitHub Actions secrets.
- Comments in the code are in Russian, the same style as the existing code; docs for users (README, CONTRIBUTING) are in English with a Russian copy in `docs/README.ru.md`. Change both READMEs together.

## Running the app by hand

`zsh build.sh` installs into `/Applications` and launches it. A second copy started from `build/` shows Sparkle update prompts and competes with the installed one for the shortcut, so check changes with the installed build.
