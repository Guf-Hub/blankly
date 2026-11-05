// Blankly — новый файл или папка там, где вы сейчас.
// Фоновое приложение: по сочетанию клавиш (по умолчанию ⌃⌥N) или при запуске из Spotlight/Дока
// показывает у курсора меню форматов, спрашивает имя и создаёт файл в открытой папке Finder
// (в другой программе — на рабочем столе). Форматы, которые на этом маке нечем открыть, скрыты.
import AppKit
import Carbon.HIToolbox
import ServiceManagement
import UniformTypeIdentifiers
import FinderSync
import Sparkle

// MARK: - Настройки и язык

let defaults = UserDefaults.standard
var lang: String {
    get { defaults.string(forKey: "lang") ?? (Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en") }
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
// Быстрые клавиши форматов: расширение ("" — папка) → [код клавиши, модификаторы]
var formatKeys: [String: [Int]] {
    get { defaults.dictionary(forKey: "formatKeys") as? [String: [Int]] ?? [:] }
    set { defaults.set(newValue, forKey: "formatKeys") }
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
    "fmtKeys": ("Клавиши форматов:", "Format shortcuts:"),
    "fmtSetup": ("Настроить…", "Set Up…"),
    "fmtTitle": ("Blankly — клавиши форматов", "Blankly — Format Shortcuts"),
    "fmtHint": ("Нажмите на поле и сочетание с ⌃⌥. Файл создаётся сразу,\nбез меню: остаётся только ввести имя.",
                "Click a field and press a shortcut with ⌃⌥. The file is created\nright away, no menu: just type a name."),
    "fmtClear": ("Убрать сочетание", "Remove shortcut"),
    "needCtrlOpt": ("Нужны ⌃ и ⌥ вместе", "Use ⌃ and ⌥ together"),
    "usedMenu": ("Уже занято: меню Blankly", "Already used: Blankly menu"),
    "usedFor": ("Уже занято: %@", "Already used: %@"),
    "usedSystem": ("Занято в macOS: Настройки → Клавиатура", "Used by macOS: Settings → Keyboard"),
    "login": ("Запускать при входе в систему", "Open at login"),
    "loginFail": ("Не удалось изменить автозапуск", "Couldn’t change login item"),
    "myTemplates": ("Мои шаблоны", "My Templates"),
    "updateAvail": ("Доступна версия %@ — обновить", "Version %@ is available — update"),
    "checkNow": ("Проверить обновления…", "Check for Updates…"),
    "finderRow": ("Правый клик в Finder: %@", "Finder right-click: %@"),
    "on": ("включён", "on"),
    "off": ("выключен", "off"),
    "finderBtn": ("Включить…", "Turn On…"),
    "checkUpdates": ("Проверять обновления раз в день", "Check for updates daily"),
    "templatesBtn": ("Папка шаблонов…", "Templates Folder…"),
    "templatesHint": ("Положите туда любой файл — он появится в меню,\nа новый файл будет его копией.",
                      "Put any file there — it shows up in the menu\nand new files are copies of it."),
]
// Окна Sparkle (и другие системные) — на языке Blankly: выбран в настройках — он, не выбран — как в системе.
// Действует со следующего запуска окна Sparkle; поэтому вызываем и при старте, и при смене языка.
func applyLanguage() {
    if let chosen = defaults.string(forKey: "lang") { defaults.set([chosen], forKey: "AppleLanguages") }
    else { defaults.removeObject(forKey: "AppleLanguages") }
}
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

// Название формата для подсказок: "" — папка
func formatTitle(_ ext: String) -> String {
    ext.isEmpty ? L("folder") : formatGroups().joined().first(where: { $0.ext == ext })?.title ?? ext
}

// Включённое сочетание macOS из «Клавиатура → Сочетания клавиш» (скриншоты, Spotlight, язык ввода…)
func systemShortcutTaken(code: UInt32, mods: UInt32) -> Bool {
    guard let all = UserDefaults(suiteName: "com.apple.symbolichotkeys")?.dictionary(forKey: "AppleSymbolicHotKeys") else { return false }
    for case let item as [String: Any] in all.values {
        guard (item["enabled"] as? Bool) == true,
              let p = (item["value"] as? [String: Any])?["parameters"] as? [Int], p.count == 3 else { continue }
        if UInt32(p[1]) == code && carbonMods(NSEvent.ModifierFlags(rawValue: UInt(p[2]))) == mods { return true }
    }
    return false
}

// Почему сочетание взять нельзя (nil — можно). owner — чьё сочетание меняем: "main" или расширение формата.
// Сочетания из меню других программ macOS узнать не даёт — поэтому для форматов требуем ⌃⌥.
func shortcutConflict(code: UInt32, mods: UInt32, owner: String) -> String? {
    if owner != "main" && code == hotKeyCode && mods == hotKeyMods { return L("usedMenu") }
    for (ext, k) in formatKeys where ext != owner && k == [Int(code), Int(mods)] {
        return String(format: L("usedFor"), formatTitle(ext))
    }
    if systemShortcutTaken(code: code, mods: mods) { return L("usedSystem") }
    return nil
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

final class App: NSObject, NSApplicationDelegate, SPUStandardUserDriverDelegate {
    var targetDir = desktopURL
    var clickPoint = NSPoint.zero // где был курсор при вызове меню — туда ставим файл на рабочем столе
    var hotKeyRef: EventHotKeyRef?
    var formatRefs: [EventHotKeyRef] = []
    var formatIDs: [UInt32: String] = [:] // id сочетания → расширение
    var settings: SettingsWindow?
    var launchedAtLogin = false
    var launchedByLink = false
    // Обновления — Sparkle: раз в день читает appcast.xml из последнего релиза на GitHub,
    // проверяет подпись ключом из Info.plist (SUPublicEDKey) и ставит новую версию сам.
    lazy var updater = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: self)
    var updateVersion: String? // нашлась новая версия — показываем пункт вверху меню

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
        _ = registerFormatKeys()
        updater.updater.automaticallyChecksForUpdates = checkUpdates
        updater.startUpdater()
        if !launchedAtLogin && !launchedByLink && !CommandLine.arguments.contains("--background") { showMenu() }
    }

    // Фоновое приложение: найденное обновление не выскакивает окном, а ждёт в меню
    var supportsGentleScheduledUpdateReminders: Bool { true }
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool { false }
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if !handleShowingUpdate { updateVersion = update.displayVersionString }
    }
    func standardUserDriverWillFinishUpdateSession() { updateVersion = nil }

    @objc func openUpdate() {
        NSApp.activate(ignoringOtherApps: true)
        updater.checkForUpdates(nil)
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
            clickPoint = NSEvent.mouseLocation
            NSApp.activate(ignoringOtherApps: true)
            let item = NSMenuItem()
            item.representedObject = ext
            pick(item)
        }
    }

    func hereDir() -> URL {
        let inFinder = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"
        return inFinder ? currentFinderFolder() : desktopURL
    }

    // Быстрая клавиша формата: без меню — сразу окно имени
    func quickCreate(_ ext: String) {
        targetDir = hereDir()
        clickPoint = NSEvent.mouseLocation
        NSApp.activate(ignoringOtherApps: true)
        let item = NSMenuItem()
        item.representedObject = ext
        pick(item)
    }

    func showMenu(in dir: URL? = nil) {
        // Где пользователь, там и создаём: в Finder — открытая папка (или стол, если кликнул по столу),
        // в любой другой программе или из Дока — рабочий стол.
        targetDir = dir ?? hereDir()

        let menu = NSMenu()
        if let v = updateVersion {
            let up = NSMenuItem(title: String(format: L("updateAvail"), v), action: #selector(openUpdate), keyEquivalent: "")
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
        let u = NSMenuItem(title: L("checkNow"), action: #selector(openUpdate), keyEquivalent: "")
        u.target = self
        menu.addItem(u)
        menu.addItem(NSMenuItem(title: L("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))

        NSApp.activate(ignoringOtherApps: true)
        // Меню целиком на экране: у нижнего/правого края сдвигаем вверх/влево.
        clickPoint = NSEvent.mouseLocation
        var at = clickPoint
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
    // Новый файл на рабочем столе — под курсор, а не в первое свободное место у правого края.
    // Если значки на столе упорядочены автоматически, Finder сам решит, куда ставить.
    func placeOnDesktop(_ url: URL) {
        guard let main = NSScreen.screens.first else { return }
        let x = Int(clickPoint.x), y = Int(main.frame.maxY - clickPoint.y) // у Finder отсчёт от верхнего края
        let name = url.lastPathComponent.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let src = """
        tell application "Finder"
            repeat 10 times
                if exists item "\(name)" of desktop then exit repeat
                delay 0.1
            end repeat
            set desktop position of item "\(name)" of desktop to {\(x), \(y)}
        end tell
        """
        var err: NSDictionary?
        NSAppleScript(source: src)?.executeAndReturnError(&err)
        if let err { NSLog("Blankly: place failed: %@", err) }
    }

    func select(_ url: URL) {
        if isDesktop(url.deletingLastPathComponent()) { placeOnDesktop(url); return }
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
        InstallEventHandler(GetApplicationEventTarget(), { _, event, ctx in
            let app = Unmanaged<App>.fromOpaque(ctx!).takeUnretainedValue()
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            DispatchQueue.main.async {
                if let ext = app.formatIDs[hk.id] { app.quickCreate(ext) } else { app.showMenu() }
            }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    // true — сочетание зарегистрировано
    func registerHotKey(code: UInt32, mods: UInt32) -> Bool {
        if let r = hotKeyRef { UnregisterEventHotKey(r); hotKeyRef = nil }
        let id = EventHotKeyID(signature: OSType(0x424C4E4B), id: 1) // 'BLNK'
        return RegisterEventHotKey(code, mods, id, GetApplicationEventTarget(), 0, &hotKeyRef) == noErr
    }

    func unregisterFormatKeys() {
        formatRefs.forEach { UnregisterEventHotKey($0) }
        formatRefs = []; formatIDs = [:]
    }

    // Регистрирует все клавиши форматов; возвращает те, что заняты другой программой
    func registerFormatKeys() -> [String] {
        unregisterFormatKeys()
        var failed: [String] = []
        for (i, ext) in formatKeys.keys.sorted().enumerated() {
            guard let k = formatKeys[ext], k.count == 2 else { continue }
            let id = UInt32(100 + i)
            var ref: EventHotKeyRef?
            if RegisterEventHotKey(UInt32(k[0]), UInt32(k[1]), EventHotKeyID(signature: OSType(0x424C4E4B), id: id),
                                   GetApplicationEventTarget(), 0, &ref) == noErr, let ref {
                formatRefs.append(ref); formatIDs[id] = ext
            } else {
                failed.append(ext)
            }
        }
        return failed
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
    let fmtLabel = NSTextField(labelWithString: "")
    let fmtButton = NSButton()
    var monitor: Any?
    var recording: (owner: String, button: NSButton, note: NSTextField)?
    // окно «Клавиши форматов»
    var fmtWindow: NSWindow?
    let fmtNote = NSTextField(labelWithString: "")
    let fmtHint = NSTextField(labelWithString: "")
    var fmtButtons: [String: NSButton] = [:]

    init(app: App) {
        self.app = app
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 394),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init()
        window.isReleasedWhenClosed = false
        window.delegate = self
        let v = window.contentView!

        hotLabel.frame = NSRect(x: 20, y: 346, width: 150, height: 20)
        hotButton.frame = NSRect(x: 175, y: 339, width: 185, height: 32)
        hotButton.bezelStyle = .rounded
        hotButton.identifier = NSUserInterfaceItemIdentifier("main")
        hotButton.target = self; hotButton.action = #selector(record(_:))
        note.frame = NSRect(x: 20, y: 322, width: 340, height: 16)
        note.alignment = .right
        note.font = .systemFont(ofSize: 11); note.textColor = .systemRed

        fmtLabel.frame = NSRect(x: 20, y: 290, width: 150, height: 20)
        fmtButton.frame = NSRect(x: 175, y: 283, width: 185, height: 32)
        fmtButton.bezelStyle = .rounded
        fmtButton.target = self; fmtButton.action = #selector(showFormatKeys)

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

        [hotLabel, hotButton, note, fmtLabel, fmtButton, langLabel, langPopup, loginBox, updatesBox, finderLabel, finderButton, templatesButton, templatesHint, version]
            .forEach { v.addSubview($0) }
    }

    func refresh() {
        window.title = L("winTitle")
        hotLabel.stringValue = L("hotkey")
        fmtLabel.stringValue = L("fmtKeys")
        fmtButton.title = L("fmtSetup")
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

    // Запись сочетания: главное (owner "main") или для формата (owner — расширение)
    @objc func record(_ sender: NSButton) {
        if recording != nil { finish(nil) }
        let owner = sender.identifier?.rawValue ?? "main"
        let n = owner == "main" ? note : fmtNote
        recording = (owner, sender, n)
        sender.title = L("press")
        n.stringValue = ""
        // пока записываем, старые сочетания не должны срабатывать
        if let r = app.hotKeyRef { UnregisterEventHotKey(r); app.hotKeyRef = nil }
        app.unregisterFormatKeys()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self else { return e }
            if e.keyCode == UInt16(kVK_Escape) { self.finish(nil); return nil }
            let mods = carbonMods(e.modifierFlags)
            if owner == "main" {
                if mods & UInt32(cmdKey | controlKey | optionKey) == 0 { n.stringValue = L("needMod"); return nil }
            } else if mods & UInt32(controlKey | optionKey) != UInt32(controlKey | optionKey) {
                n.stringValue = L("needCtrlOpt"); return nil
            }
            self.finish((UInt32(e.keyCode), mods))
            return nil
        }
    }

    func finish(_ combo: (UInt32, UInt32)?) {
        stopRecording()
        guard let r = recording else { return }
        recording = nil
        if let (code, mods) = combo {
            if let why = shortcutConflict(code: code, mods: mods, owner: r.owner) {
                r.note.stringValue = why
            } else if r.owner == "main" {
                if app.registerHotKey(code: code, mods: mods) { hotKeyCode = code; hotKeyMods = mods }
                else { r.note.stringValue = L("busy") }
            } else {
                formatKeys[r.owner] = [Int(code), Int(mods)]
                if app.registerFormatKeys().contains(r.owner) {
                    formatKeys[r.owner] = nil
                    r.note.stringValue = L("busy")
                }
            }
        }
        if app.hotKeyRef == nil { _ = app.registerHotKey(code: hotKeyCode, mods: hotKeyMods) }
        _ = app.registerFormatKeys()
        hotButton.title = shortcutText(code: hotKeyCode, mods: hotKeyMods)
        refreshFormatKeys()
    }

    func stopRecording() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    // MARK: окно «Клавиши форматов»: папка и форматы, которые есть чем открыть

    @objc func showFormatKeys() {
        if fmtWindow == nil { buildFormatWindow() }
        fmtWindow?.title = L("fmtTitle")
        fmtHint.stringValue = L("fmtHint")
        fmtNote.stringValue = ""
        refreshFormatKeys()
        fmtWindow?.center()
        fmtWindow?.makeKeyAndOrderFront(nil)
    }

    func buildFormatWindow() {
        let rows = [("", L("folder"))] + formatGroups().joined().filter { appFor($0.ext) != nil }.map { ($0.ext, $0.title) }
        let h = CGFloat(rows.count * 32 + 96)
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: h), styleMask: [.titled, .closable],
                         backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.delegate = self
        let v = w.contentView!
        fmtHint.frame = NSRect(x: 20, y: h - 50, width: 360, height: 34)
        fmtHint.font = .systemFont(ofSize: 11); fmtHint.textColor = .secondaryLabelColor
        v.addSubview(fmtHint)
        for (i, (ext, title)) in rows.enumerated() {
            let y = h - 92 - CGFloat(i * 32)
            let label = NSTextField(labelWithString: title)
            label.frame = NSRect(x: 20, y: y + 6, width: 200, height: 20)
            let b = NSButton(frame: NSRect(x: 220, y: y, width: 130, height: 32))
            b.bezelStyle = .rounded
            b.identifier = NSUserInterfaceItemIdentifier(ext)
            b.target = self; b.action = #selector(record(_:))
            let x = NSButton(frame: NSRect(x: 350, y: y + 4, width: 30, height: 24))
            x.bezelStyle = .inline; x.isBordered = false
            x.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: L("fmtClear"))
            x.toolTip = L("fmtClear")
            x.identifier = NSUserInterfaceItemIdentifier(ext)
            x.target = self; x.action = #selector(clearFormatKey(_:))
            [label, b, x].forEach { v.addSubview($0) }
            fmtButtons[ext] = b
        }
        fmtNote.frame = NSRect(x: 20, y: 16, width: 360, height: 16)
        fmtNote.font = .systemFont(ofSize: 11); fmtNote.textColor = .systemRed
        v.addSubview(fmtNote)
        fmtWindow = w
    }

    func refreshFormatKeys() {
        let keys = formatKeys
        for (ext, b) in fmtButtons {
            if let k = keys[ext], k.count == 2 { b.title = shortcutText(code: UInt32(k[0]), mods: UInt32(k[1])) }
            else { b.title = "—" }
        }
    }

    @objc func clearFormatKey(_ sender: NSButton) {
        if recording != nil { finish(nil) }
        formatKeys[sender.identifier?.rawValue ?? ""] = nil
        _ = app.registerFormatKeys()
        refreshFormatKeys()
    }

    @objc func openTemplates() {
        try? FileManager.default.createDirectory(at: userTemplatesDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(userTemplatesDir)
    }

    @objc func changeLang() {
        lang = langPopup.indexOfSelectedItem == 1 ? "en" : "ru"
        applyLanguage()
        fmtWindow?.close(); fmtWindow = nil; fmtButtons = [:] // пересоберётся на новом языке
        refresh()
    }

    @objc func openFinderExtensions() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc func toggleUpdates() {
        checkUpdates = updatesBox.state == .on
        app.updater.updater.automaticallyChecksForUpdates = checkUpdates
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

applyLanguage()
let nsApp = NSApplication.shared
let delegate = App()
nsApp.delegate = delegate
nsApp.setActivationPolicy(.accessory)
nsApp.run()
