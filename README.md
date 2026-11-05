<p align="center"><img src="docs/icon.png" width="128" alt=""></p>

<h1 align="center">Blankly</h1>

<p align="center">Create a new file or folder right where you are on macOS.<br>
Press <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>N</kbd>, pick a format, type a name.</p>

<p align="center"><a href="https://github.com/Guf-Hub/blankly/releases/latest"><b>⬇ Download for macOS</b></a></p>

<p align="center"><b>English</b> | <a href="README.ru.md">Русский</a></p>

---

macOS has no "New → Text Document" like Windows does. Blankly adds it as a small background app.

## How it works

- Press **Control + Option + N**. A menu opens next to the cursor.
- Or right-click an empty spot in a Finder window → **New File** → pick a format (turn it on once in Settings).
- Or add the Blankly button to the Finder toolbar: right-click the toolbar → **Customize Toolbar…** → drag Blankly onto it.
- Choose **New Folder** or a file format, type a name, press Enter.
- The file is created in the folder open in Finder. If you are in another app, it goes to the Desktop.
- Only formats your Mac can open are shown. No Word or Pages — no `.docx` in the menu.

Formats: `txt`, `md`, `json`, `csv`, `html`, `py`, `docx`, `xlsx`, `pptx`, `odt`, `ods`, `odp`.
Office files are real empty documents, not zero-byte files, so Word, Excel and LibreOffice open them without complaints.

Files are empty, except `html` (an HTML5 starter page) and Office documents.

**Your own templates.** Settings → **Templates Folder…** opens a folder. Any file you put there shows up in the menu under *My Templates*, and new files are copies of it — a `.py` with your boilerplate, a `.yaml` config, anything.

Settings (bottom of the menu): shortcut, language (English / Русский), open at login, Finder right-click, update check, templates folder.

**Updates.** Once a day Blankly asks GitHub whether a newer release exists and shows *Version X is available* at the top of the menu. Nothing else is sent. You can turn it off in Settings.

## Install

**Homebrew:**

```bash
brew tap guf-hub/tap
brew trust --cask guf-hub/tap/blankly
brew install --cask guf-hub/tap/blankly
```

**Or manually:**

1. Download `Blankly-x.y.dmg` from [Releases](../../releases), open it and drag Blankly to Applications.
2. Open Blankly. The app is not notarized by Apple, so macOS blocks the first launch:
   **System Settings → Privacy & Security → "Blankly was blocked" → Open Anyway**.
3. When asked whether Blankly may control Finder, click **Allow**. It needs this to know which folder is open.
4. Open **Settings…** from the menu and turn on **Open at login**.
5. For the right-click item: Settings → **Turn On…** next to *Finder right-click* → enable Blankly in the list. The toolbar button is optional: right-click the Finder toolbar → **Customize Toolbar…** → drag Blankly onto it.

Requires macOS 13 or later. Apple Silicon and Intel.

## Build from source

Needs Xcode or Command Line Tools.

```bash
zsh build.sh              # build and install to /Applications
zsh build.sh --no-install # build only: build/Blankly.app, .zip and .dmg
```

`main.swift` is the whole app, `icon.swift` draws the icon, `Resources/templates` holds the empty Office documents.

## Author

Made by [Guf-Hub](https://github.com/Guf-Hub). Ideas and bug reports — [Issues](../../issues).

## License

MIT
