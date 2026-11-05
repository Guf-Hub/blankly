// Blankly — новый файл или папка там, где вы сейчас.
// Фоновое приложение: по сочетанию клавиш (по умолчанию ⌃⌥N) или при запуске из Spotlight/Дока
// показывает у курсора меню форматов, спрашивает имя и создаёт файл в открытой папке Finder
// (в другой программе — на рабочем столе). Форматы, которые на этом маке нечем открыть, скрыты.
import AppKit
import Carbon.HIToolbox
import ServiceManagement
import UniformTypeIdentifiers
import FinderSync

// MARK: - Настройки и язык

let defaults = UserDefaults.standard
var lang: String {
    get { defaults.string(forKey: "lang") ?? "en" }
    set { defaults.set(newValue, forKey: "lang") }
}
var checkUpdates: Bool {
    get { defaults.object(forKey: "checkUpdates") as? Bool ?? true }
    set { defaults.set(newValue, forKey: "checkUpdates") }
}
var hotKeyCode: UInt32 {
    get { defaults.object(forKey: "keyCode") as? UInt32 ?? UInt32(kVK_ANSI_N) }
    set { defaults.set(newValue, forKey: "keyCode") }
}
var hotKeyMods: UInt32 {
    get { defaults.object(forKey: "mods") as? UInt32 ?? UInt32(controlKey | optionKey) }
    set { defaults.set(newValue, forKey: "mods") }
}

let strings: [String: (ru: String, en: String)] = [
    "base": ("Новый файл", "New File"),
    "createIn": ("Создать в «%@»", "Create in “%@”"),
    "desktop": ("Рабочий стол", "Desktop"),
    "folder": ("Новая папка", "New Folder"),
    "settings": ("Настройки…", "Settings…"),
    "quit": ("Выйти из Blankly", "Quit Blankly"),
    "text": ("Текст", "Text"),
    "lo_text": ("LibreOffice Текст", "LibreOffice Text"),
    "lo_calc": ("LibreOffice Таблица", "LibreOffice Spreadsheet"),
    "lo_impress": ("LibreOffice Презентация", "LibreOffice Presentation"),
    "askFolder": ("Имя новой папки", "Name of the new folder"),
    "askFile": ("Имя нового файла", "Name of the new file"),
    "askWhere": ("Будет создано в «%@»", "Will be created in “%@”"),
    "create": ("Создать", "Create"),
    "cancel": ("Отмена", "Cancel"),
    "failTitle": ("Не удалось создать «%@»", "Couldn’t create “%@”"),
    "failText": ("Возможно, в эту папку нельзя записывать.", "You may not have permission to write to this folder."),
    "winTitle": ("Blankly — настройки", "Blankly — Settings"),
    "hotkey": ("Сочетание клавиш:", "Shortcut:"),
    "press": ("Нажмите сочетание…", "Press shortcut…"),
    "needMod": ("Нужна клавиша ⌘, ⌃ или ⌥", "Use ⌘, ⌃ or ⌥"),
    "busy": ("Сочетание занято другой программой", "Shortcut is used by another app"),
    "language": ("Язык:", "Language:"),
    "login": ("Запускать при входе в систему", "Open at login"),
    "loginFail": ("Не удалось изменить автозапуск", "Couldn’t change login item"),
    "myTemplates": ("Мои шаблоны", "My Templates"),
    "updateAvail": ("Доступна версия %@ — скачать", "Version %@ is available — download"),
    "finderRow": ("Правый клик в Finder: %@", "Finder right-click: %@"),
    "on": ("включён", "on"),
    "off": ("выключен", "off"),
    "finderBtn": ("Включить…", "Turn On…"),
    "checkUpdates": ("Проверять обновления раз в день", "Check for updates daily"),
    "templatesBtn": ("Папка шаблонов…", "Templates Folder…"),
    "templatesHint": ("Положите туда любой файл — он появится в меню,\nа новый файл будет его копией.",
                      "Put any file there — it shows up in the menu\nand new files are copies of it."),
]
func L(_ k: String) -> String { let s = strings[k]!; return lang == "en" ? s.en : s.ru }

struct Format { let ext: String; let title: String }
func formatGroups() -> [[Format]] {
    [[Format(ext: "txt", title: "\(L("text")) (.txt)"),
      Format(ext: "md", title: "Markdown (.md)"),
      Format(ext: "json", title: "JSON (.json)"),
      Format(ext: "csv", title: "CSV (.csv)"),
      Format(ext: "html", title: "HTML (.html)"),
      Format(ext: "py", title: "Python (.py)")],
     [Format(ext: "docx", title: "Word (.docx)"),
      Format(ext: "xlsx", title: "Excel (.xlsx)"),
      Format(ext: "pptx", title: "PowerPoint (.pptx)")],
     [Format(ext: "odt", title: "\(L("lo_text")) (.odt)"),
      Format(ext: "ods", title: "\(L("lo_calc")) (.ods)"),
      Format(ext: "odp", title: "\(L("lo_impress")) (.odp)")]]
}

// Программа, которая откроет такой файл (Office, LibreOffice, iWork, TextEdit, редактор кода…)
func appFor(_ ext: String) -> URL? {
    UTType(filenameExtension: ext).flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
}

// Встроенные файлы пустые; у html — стандартная заготовка HTML5.
func starterText(_ ext: String) -> String {
    guard ext == "html" else { return "" }
    return """
    <!DOCTYPE html>
    <html lang="\(lang)">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Document</title>
    </head>
    <body>

    </body>
    </html>

    """
}

// Свои шаблоны: любой файл в этой папке появляется в меню, новый файл — его копия.
let userTemplatesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Blankly/Templates", isDirectory: true)

func userTemplates() -> [URL] {
    let items = (try? FileManager.default.contentsOfDirectory(
        at: userTemplatesDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])) ?? []
    return items
        .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true && !$0.pathExtension.isEmpty }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
}

// MARK: - Файлы

let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]

func isDesktop(_ dir: URL) -> Bool { dir.standardizedFileURL == desktopURL.standardizedFileURL }

// Папка, открытая в Finder (или рабочий стол, если понять нельзя).
func currentFinderFolder() -> URL {
    let src = """
    tell application "Finder"
        try
            set l to insertion location
            if class of l is folder or class of l is disk then return POSIX path of (l as alias)
        end try
    end tell
    return ""
    """
    var err: NSDictionary?
    let path = NSAppleScript(source: src)?.executeAndReturnError(&err).stringValue ?? ""
    return path.isEmpty ? desktopURL : URL(fileURLWithPath: path, isDirectory: true)
}

// Свободное имя: «Имя.ext», «Имя 1.ext», … (ext пустой — для папки)
func freeURL(in dir: URL, base: String, ext: String) -> URL {
    let suffix = ext.isEmpty ? "" : ".\(ext)"
    var url = dir.appendingPathComponent(base + suffix)
    var n = 1
    while FileManager.default.fileExists(atPath: url.path) {
        url = dir.appendingPathComponent("\(base) \(n)\(suffix)")
        n += 1
    }
    return url
}

// Имя из поля ввода → безопасное имя файла без расширения
func cleanBase(_ typed: String, ext: String, fallback: String) -> String {
    var s = typed.trimmingCharacters(in: .whitespacesAndNewlines)
    if !ext.isEmpty, s.lowercased().hasSuffix("." + ext) { s = String(s.dropLast(ext.count + 1)) }
    s = s.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    while s.hasPrefix(".") { s.removeFirst() } // не делаем скрытые файлы
    return s.isEmpty ? fallback : s
}

// template — свой шаблон пользователя (копируется как есть)
func create(ext: String, base: String, in dir: URL, template: URL? = nil) -> URL? {
    let fm = FileManager.default
    let url = freeURL(in: dir, base: base, ext: ext)
    do {
        if ext.isEmpty {
            try fm.createDirectory(at: url, withIntermediateDirectories: false)
        } else if let tpl = template ?? Bundle.main.url(forResource: "empty", withExtension: ext, subdirectory: "templates") {
            try fm.copyItem(at: tpl, to: url)
        } else {
            try Data(starterText(ext).utf8).write(to: url, options: .withoutOverwriting)
        }
    } catch { return nil }
    return url
}

// MARK: - Обновления

let repoAPI = URL(string: "https://api.github.com/repos/Guf-Hub/blankly/releases/latest")!
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

// "1.10" > "1.9": сравниваем по числам
func isNewer(_ a: String, than b: String) -> Bool {
    let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
    for i in 0..<max(x.count, y.count) {
        let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
        if l != r { return l > r }
    }
    return false
}

// MARK: - Сочетание клавиш

let keyNames: [Int: String] = {
    var m: [Int: String] = [:]
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map(String.init)
    let codes = [kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H,
                 kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P,
                 kVK_ANSI_Q, kVK_ANSI_R, kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
                 kVK_ANSI_Y, kVK_ANSI_Z, kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
                 kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
    for (k, v) in zip(codes, letters) { m[k] = v }
    let fkeys = [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12]
    for (i, k) in fkeys.enumerated() { m[k] = "F\(i + 1)" }
    m[kVK_Space] = "Space"; m[kVK_Return] = "↩"
    return m
}()

func shortcutText(code: UInt32, mods: UInt32) -> String {
    var s = ""
    if mods & UInt32(controlKey) != 0 { s += "⌃" }
    if mods & UInt32(optionKey) != 0 { s += "⌥" }
    if mods & UInt32(shiftKey) != 0 { s += "⇧" }
    if mods & UInt32(cmdKey) != 0 { s += "⌘" }
    return s + (keyNames[Int(code)] ?? "#\(code)")
}

func carbonMods(_ f: NSEvent.ModifierFlags) -> UInt32 {
    var m: UInt32 = 0
    if f.contains(.control) { m |= UInt32(controlKey) }
    if f.contains(.option) { m |= UInt32(optionKey) }
    if f.contains(.shift) { m |= UInt32(shiftKey) }
    if f.contains(.command) { m |= UInt32(cmdKey) }
    return m
}

// MARK: - Приложение

final class App: NSObject, NSApplicationDelegate {
    var targetDir = desktopURL
    var hotKeyRef: EventHotKeyRef?
    var settings: SettingsWindow?
    var launchedAtLogin = false
    var launchedByLink = false
    var update: (version: String, page: URL)?
    var updateTimer: Timer?

    func applicationWillFinishLaunching(_ n: Notification) {
        // Запуск как объект входа (автозапуск) — меню не показываем.
        let ev = NSAppleEventManager.shared().currentAppleEvent
        launchedAtLogin = ev?.eventID == AEEventID(kAEOpenApplication)
            && ev?.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue == OSType(keyAELaunchedAsLogInItem)
        launchedByLink = ev?.eventID == AEEventID(kAEGetURL)
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        installHotKeyHandler()
        if !registerHotKey(code: hotKeyCode, mods: hotKeyMods) {
            openSettings(); settings?.note.stringValue = L("busy")
            return
        }
        startUpdateChecks()
        if !launchedAtLogin && !launchedByLink && !CommandLine.arguments.contains("--background") { showMenu() }
    }

    // Раз в день спрашиваем GitHub о последнем релизе. Никаких данных не отправляем.
    func startUpdateChecks() {
        updateTimer?.invalidate()
        guard checkUpdates else { update = nil; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.checkForUpdate() }
        updateTimer = Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { _ in self.checkForUpdate() }
    }

    func checkForUpdate() {
        var req = URLRequest(url: repoAPI)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let page = (json["html_url"] as? String).flatMap(URL.init(string:)) else { return }
            let v = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            DispatchQueue.main.async { self.update = isNewer(v, than: appVersion) ? (v, page) : nil }
        }.resume()
    }

    @objc func openUpdate() {
        if let u = update { NSWorkspace.shared.open(u.page) }
    }

    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows f: Bool) -> Bool {
        showMenu()
        return false
    }

    // Ссылка от расширения Finder: blankly://new?path=/папка[&ext=txt|folder]
    // Без ext — полное меню Blankly, с ext — сразу спрашиваем имя.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "blankly" && url.host == "new" {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let path = items.first(where: { $0.name == "path" })?.value ?? ""
            var isDir: ObjCBool = false
            guard !path.isEmpty, FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
            let dir = URL(fileURLWithPath: path, isDirectory: true)
            guard let raw = items.first(where: { $0.name == "ext" })?.value else { showMenu(in: dir); continue }
            let ext = raw == "folder" ? "" : raw
            // только известные форматы: ссылку может открыть кто угодно
            guard ext.isEmpty || formatGroups().joined().contains(where: { $0.ext == ext }) else { continue }
            targetDir = dir
            NSApp.activate(ignoringOtherApps: true)
            let item = NSMenuItem()
            item.representedObject = ext
            pick(item)
        }
    }

    func showMenu(in dir: URL? = nil) {
        // Где пользователь, там и создаём: в Finder — открытая папка (или стол, если кликнул по столу),
        // в любой другой программе или из Дока — рабочий стол.
        if let dir {
            targetDir = dir
        } else {
            let inFinder = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"
            targetDir = inFinder ? currentFinderFolder() : desktopURL
        }

        let menu = NSMenu()
        if let u = update {
            let up = NSMenuItem(title: String(format: L("updateAvail"), u.version), action: #selector(openUpdate), keyEquivalent: "")
            up.target = self
            up.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            menu.addItem(up)
            menu.addItem(.separator())
        }
        let header = NSMenuItem(title: String(format: L("createIn"), name(of: targetDir)), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())
        menu.addItem(item(L("folder"), ext: "", icon: NSWorkspace.shared.icon(for: .folder)))
        for group in formatGroups() {
            let shown = group.filter { appFor($0.ext) != nil }
            if shown.isEmpty { continue }
            menu.addItem(.separator())
            for f in shown {
                let icon = UTType(filenameExtension: f.ext).map { NSWorkspace.shared.icon(for: $0) }
                menu.addItem(item(f.title, ext: f.ext, icon: icon))
            }
        }
        let mine = userTemplates().filter { appFor($0.pathExtension) != nil }
        if !mine.isEmpty {
            menu.addItem(.separator())
            let h = NSMenuItem(title: L("myTemplates"), action: nil, keyEquivalent: "")
            h.isEnabled = false
            menu.addItem(h)
            for t in mine {
                let it = item(t.deletingPathExtension().lastPathComponent + " (.\(t.pathExtension))",
                              ext: t.pathExtension, icon: NSWorkspace.shared.icon(forFile: t.path))
                it.representedObject = t
                menu.addItem(it)
            }
        }
        menu.addItem(.separator())
        let s = NSMenuItem(title: L("settings") + "   " + shortcutText(code: hotKeyCode, mods: hotKeyMods),
                           action: #selector(openSettings), keyEquivalent: "")
        s.target = self
        menu.addItem(s)
        menu.addItem(NSMenuItem(title: L("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))

        NSApp.activate(ignoringOtherApps: true)
        // Меню целиком на экране: у нижнего/правого края сдвигаем вверх/влево.
        var at = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(at, $0.frame, false) }) ?? NSScreen.main {
            let vis = screen.visibleFrame
            at.y = min(max(at.y, vis.minY + menu.size.height), vis.maxY)
            at.x = max(min(at.x, vis.maxX - menu.size.width), vis.minX)
        }
        menu.popUp(positioning: nil, at: at, in: nil)
    }

    func item(_ title: String, ext: String, icon: NSImage?) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: #selector(pick(_:)), keyEquivalent: "")
        it.target = self
        it.representedObject = ext
        if let icon = icon?.copy() as? NSImage { icon.size = NSSize(width: 16, height: 16); it.image = icon }
        return it
    }

    func name(of dir: URL) -> String { isDesktop(dir) ? L("desktop") : dir.lastPathComponent }

    @objc func pick(_ sender: NSMenuItem) {
        // representedObject: расширение (встроенный формат, "" — папка) или URL своего шаблона
        let template = sender.representedObject as? URL
        guard let ext = template?.pathExtension ?? sender.representedObject as? String else { return }
        let fallback = ext.isEmpty ? L("folder") : L("base")
        guard let base = askName(ext: ext, fallback: fallback) else { return }
        if let url = create(ext: ext, base: base, in: targetDir, template: template) {
            select(url)
        } else {
            NSSound.beep()
            let a = NSAlert()
            a.messageText = String(format: L("failTitle"), base)
            a.informativeText = L("failText")
            a.runModal()
        }
    }

    // Окно с именем: поле заполнено и выделено (без расширения), Enter — создать, Esc — отмена.
    func askName(ext: String, fallback: String) -> String? {
        let a = NSAlert()
        a.messageText = ext.isEmpty ? L("askFolder") : L("askFile")
        a.informativeText = String(format: L("askWhere"), name(of: targetDir))
        a.icon = ext.isEmpty ? NSWorkspace.shared.icon(for: .folder)
            : UTType(filenameExtension: ext).map { NSWorkspace.shared.icon(for: $0) }
        a.addButton(withTitle: L("create"))
        a.addButton(withTitle: L("cancel"))
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = ext.isEmpty ? fallback : "\(fallback).\(ext)"
        a.accessoryView = field
        a.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            field.currentEditor()?.selectedRange = NSRange(location: 0, length: (fallback as NSString).length)
        }
        guard a.runModal() == .alertFirstButtonReturn else { return nil }
        return cleanBase(field.stringValue, ext: ext, fallback: fallback)
    }

    // Выделить созданное в уже открытом окне Finder. На рабочем столе не трогаем:
    // Finder на «select» открыл бы окно стола.
    func select(_ url: URL) {
        if isDesktop(url.deletingLastPathComponent()) { return }
        let p = url.path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let src = """
        set f to (POSIX file "\(p)") as alias
        tell application "Finder"
            activate
            select f
        end tell
        """
        var err: NSDictionary?
        NSAppleScript(source: src)?.executeAndReturnError(&err)
        if let err { NSLog("Blankly: select failed: %@", err) }
    }

    @objc func openSettings() {
        if settings == nil { settings = SettingsWindow(app: self) }
        settings!.show()
    }

    func installHotKeyHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            let app = Unmanaged<App>.fromOpaque(ctx!).takeUnretainedValue()
            DispatchQueue.main.async { app.showMenu() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    // true — сочетание зарегистрировано
    func registerHotKey(code: UInt32, mods: UInt32) -> Bool {
        if let r = hotKeyRef { UnregisterEventHotKey(r); hotKeyRef = nil }
        let id = EventHotKeyID(signature: OSType(0x424C4E4B), id: 1) // 'BLNK'
        return RegisterEventHotKey(code, mods, id, GetApplicationEventTarget(), 0, &hotKeyRef) == noErr
    }
}

// MARK: - Окно настроек

final class SettingsWindow: NSObject, NSWindowDelegate {
    let app: App
    let window: NSWindow
    let hotLabel = NSTextField(labelWithString: "")
    let langLabel = NSTextField(labelWithString: "")
    let hotButton = NSButton()
    let note = NSTextField(labelWithString: "")
    let langPopup = NSPopUpButton()
    let loginBox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let updatesBox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let finderLabel = NSTextField(labelWithString: "")
    let finderButton = NSButton()
    let version = NSTextField(labelWithString: "")
    let templatesButton = NSButton()
    let templatesHint = NSTextField(labelWithString: "")
    var monitor: Any?

    init(app: App) {
        self.app = app
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 350),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init()
        window.isReleasedWhenClosed = false
        window.delegate = self
        let v = window.contentView!

        hotLabel.frame = NSRect(x: 20, y: 302, width: 150, height: 20)
        hotButton.frame = NSRect(x: 175, y: 295, width: 185, height: 32)
        hotButton.bezelStyle = .rounded
        hotButton.target = self; hotButton.action = #selector(record)
        note.frame = NSRect(x: 175, y: 278, width: 200, height: 16)
        note.font = .systemFont(ofSize: 11); note.textColor = .systemRed

        langLabel.frame = NSRect(x: 20, y: 246, width: 150, height: 20)
        langPopup.frame = NSRect(x: 175, y: 240, width: 185, height: 30)
        langPopup.addItems(withTitles: ["Русский", "English"])
        langPopup.target = self; langPopup.action = #selector(changeLang)

        loginBox.frame = NSRect(x: 20, y: 202, width: 340, height: 20)
        loginBox.target = self; loginBox.action = #selector(toggleLogin)
        updatesBox.frame = NSRect(x: 20, y: 172, width: 340, height: 20)
        updatesBox.target = self; updatesBox.action = #selector(toggleUpdates)
        finderLabel.frame = NSRect(x: 20, y: 134, width: 230, height: 20)
        finderButton.frame = NSRect(x: 245, y: 127, width: 120, height: 32)
        finderButton.bezelStyle = .rounded
        finderButton.target = self; finderButton.action = #selector(openFinderExtensions)

        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        version.stringValue = "Blankly \(ver)"
        version.frame = NSRect(x: 20, y: 16, width: 340, height: 16)
        version.font = .systemFont(ofSize: 11); version.textColor = .tertiaryLabelColor

        templatesButton.frame = NSRect(x: 14, y: 84, width: 200, height: 32)
        templatesButton.bezelStyle = .rounded
        templatesButton.target = self; templatesButton.action = #selector(openTemplates)
        templatesHint.frame = NSRect(x: 20, y: 46, width: 340, height: 34)
        templatesHint.font = .systemFont(ofSize: 11); templatesHint.textColor = .secondaryLabelColor

        [hotLabel, hotButton, note, langLabel, langPopup, loginBox, updatesBox, finderLabel, finderButton, templatesButton, templatesHint, version]
            .forEach { v.addSubview($0) }
    }

    func refresh() {
        window.title = L("winTitle")
        hotLabel.stringValue = L("hotkey")
        langLabel.stringValue = L("language")
        loginBox.title = L("login")
        updatesBox.title = L("checkUpdates")
        let finderOn = FIFinderSyncController.isExtensionEnabled
        finderLabel.stringValue = String(format: L("finderRow"), finderOn ? L("on") : L("off"))
        finderButton.title = L("finderBtn")
        finderButton.isHidden = finderOn
        updatesBox.state = checkUpdates ? .on : .off
        templatesButton.title = L("templatesBtn")
        templatesHint.stringValue = L("templatesHint")
        hotButton.title = shortcutText(code: hotKeyCode, mods: hotKeyMods)
        langPopup.selectItem(at: lang == "en" ? 1 : 0)
        loginBox.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func show() {
        refresh()
        note.stringValue = ""
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc func record() {
        stopRecording()
        hotButton.title = L("press")
        note.stringValue = ""
        if let r = app.hotKeyRef { UnregisterEventHotKey(r); app.hotKeyRef = nil } // чтобы старое не сработало
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self else { return e }
            if e.keyCode == UInt16(kVK_Escape) { self.finish(nil); return nil }
            let mods = carbonMods(e.modifierFlags)
            if mods & UInt32(cmdKey | controlKey | optionKey) == 0 { self.note.stringValue = L("needMod"); return nil }
            self.finish((UInt32(e.keyCode), mods))
            return nil
        }
    }

    func finish(_ combo: (UInt32, UInt32)?) {
        stopRecording()
        if let (code, mods) = combo {
            if app.registerHotKey(code: code, mods: mods) {
                hotKeyCode = code; hotKeyMods = mods
            } else {
                note.stringValue = L("busy")
                _ = app.registerHotKey(code: hotKeyCode, mods: hotKeyMods)
            }
        } else {
            _ = app.registerHotKey(code: hotKeyCode, mods: hotKeyMods)
        }
        hotButton.title = shortcutText(code: hotKeyCode, mods: hotKeyMods)
    }

    func stopRecording() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    @objc func openTemplates() {
        try? FileManager.default.createDirectory(at: userTemplatesDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(userTemplatesDir)
    }

    @objc func changeLang() {
        lang = langPopup.indexOfSelectedItem == 1 ? "en" : "ru"
        refresh()
    }

    @objc func openFinderExtensions() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc func toggleUpdates() {
        checkUpdates = updatesBox.state == .on
        app.startUpdateChecks()
    }

    @objc func toggleLogin() {
        do {
            if loginBox.state == .on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            note.stringValue = L("loginFail")
        }
        refresh()
    }

    func windowDidBecomeKey(_ n: Notification) { refresh() }

    func windowWillClose(_ n: Notification) {
        if monitor != nil { finish(nil) }
    }
}

// MARK: - Запуск

let nsApp = NSApplication.shared
let delegate = App()
nsApp.delegate = delegate
nsApp.setActivationPolicy(.accessory)
nsApp.run()
