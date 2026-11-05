<p align="center"><img src="docs/icon.png" width="128" alt=""></p>

<h1 align="center">Blankly</h1>

<p align="center">Create a new file or folder right where you are on macOS.<br>
Press <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>N</kbd>, pick a format, type a name.</p>

<p align="center"><a href="https://github.com/Guf-Hub/blankly/releases/latest"><b>⬇ Download for macOS</b></a></p>

<p align="center"><b>English</b> | <a href="README.ru.md">Русский</a></p>

<p align="center"><img src="docs/demo.gif" width="600" alt="Blankly creating a text file and a folder on the Desktop"></p>

---

macOS has no "New → Text Document" like Windows does. Blankly adds it as a small background app.

## How it works

There are three ways to open Blankly:

- Press **Control + Option + N** anywhere. A menu opens next to the cursor.
- Right-click an empty spot in a Finder window or on the Desktop → **New File** → pick a format.
- Click the Blankly button in the Finder toolbar (see [Finder](#finder) below).
- Or give a format its own shortcut — say **Control + Option + W** for Word — and skip the menu entirely (see [Settings](#settings)).

Then choose **New Folder** or a file format, type a name and press Enter. The name is pre-filled and selected, so you can just start typing.

**Where the file goes**

- In Finder — into the folder open in the front window. The new file is selected.
- In any other app — onto the Desktop, right where the cursor was.
- If the name is taken, Blankly adds a number: `Notes 1.txt`.

**Formats:** `txt`, `md`, `json`, `csv`, `html`, `py`, `docx`, `xlsx`, `pptx`, `odt`, `ods`, `odp`.

- Only formats your Mac can open are shown. No Word or Pages — no `.docx` in the menu.
- Files are empty, except `html` (an HTML5 starter page) and Office documents.
- Office files are real empty documents, not zero-byte files, so Word, Excel and LibreOffice open them without complaints.

**Your own templates.** Settings → **Templates Folder…** opens a folder. Any file you put there shows up in the menu under *My Templates*, and new files are copies of it — a `.py` with your boilerplate, a `.yaml` config, anything. In the Finder menu they are under **More…**.

## Settings

Open the menu (Control + Option + N) → **Settings…** at the bottom.

| Setting | What it does |
|---|---|
| Shortcut | Click the field and press a new combination. It must include ⌘, ⌃ or ⌥. Esc cancels. If another app already uses it, Blankly says so. |
| Format shortcuts | **Set Up…** opens a list: New Folder and every format. Click a field and press **Control + Option** + a key. Pressing it later asks for a name and creates that file right away, no menu. Blankly warns if the shortcut is already used by its menu, another format, macOS (Settings → Keyboard → Keyboard Shortcuts) or another app. Control + Option is required because macOS can't tell which shortcuts other apps use inside their own menus, and those rarely use this pair. |
| Language | English or Русский. By default Blankly follows the system: Russian on a Russian Mac, English otherwise. |
| Open at login | Starts Blankly in the background when you log in, so the shortcut always works. |
| Finder right-click | **Turn On…** opens the macOS list of Finder extensions; enable Blankly there. |
| Check for updates daily | See [Updates](#updates). |
| Templates Folder… | Opens the folder with your own templates. |

## Finder

Right-click and the toolbar button come from a Finder extension inside Blankly. Turn it on once: Settings → **Turn On…** next to *Finder right-click* → enable Blankly in the list.

The toolbar button is optional. Right-click the Finder toolbar → **Customize Toolbar…** → drag Blankly onto it. Click it to get the same list of formats.

macOS always puts items from apps at the bottom of the right-click menu — Blankly can't move its item higher.

## Updates

Once a day Blankly asks GitHub whether a newer release exists and shows *Version X is available* at the top of the menu. Nothing else is sent. You can turn it off in Settings.

## Install

**Homebrew:**

```bash
brew tap guf-hub/tap
brew trust --cask guf-hub/tap/blankly
brew install --cask guf-hub/tap/blankly
```

**Or manually:** download `Blankly-x.y.dmg` from [Releases](../../releases), open it and drag Blankly to Applications.

**First launch** (both ways):

1. Open Blankly from Applications. Blankly is not notarized by Apple (that needs a paid developer account), so the first time macOS shows *"Blankly.app" Not Opened — Apple could not verify…*. This is expected. To get past it once:
   1. Click **Done**. Do **not** click *Move to Trash*.
   2. Open  → **System Settings** → **Privacy & Security**.
   3. Scroll down to *Security*. Next to *"Blankly.app" was blocked…* click **Open Anyway** and confirm with your password or Touch ID.
   4. In the dialog that appears, click **Open Anyway** again.

   After that Blankly opens normally. Prefer the Terminal? This does the same:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Blankly.app
   ```
2. When asked whether Blankly may control Finder, click **Allow**. It needs this to know which folder is open.
3. Open **Settings…** and turn on **Open at login**.
4. Optional: turn on the Finder extension — see [Finder](#finder).

Requires macOS 13 or later. Apple Silicon and Intel.

## Uninstall

```bash
brew uninstall --zap --cask blankly
```

Without Homebrew: quit Blankly (menu → **Quit Blankly**), move it from Applications to the Trash, and delete `~/Library/Application Support/Blankly` (your templates) if you don't need it.

## Build from source

Needs Xcode or Command Line Tools.

```bash
zsh build.sh              # build and install to /Applications
zsh build.sh --no-install # build only: build/Blankly.app, .zip and .dmg
```

`main.swift` is the whole app, `FinderExtension.swift` is the Finder extension, `icon.swift` draws the icon, `Resources/templates` holds the empty Office documents.

## Support

Blankly is free. If it saves you time and you'd like to say thanks — send **USDT on the TON network** to:

```
UQBQ3pthdJ3qGhAgNbeo95fsqeauO1R65JFuCPlVdbvvJEvF
```

Only USDT and only on TON. Other coins or networks sent there will be lost.

## Author

Made by [Guf-Hub](https://github.com/Guf-Hub). Ideas and bug reports — [Issues](../../issues).

## License

MIT
