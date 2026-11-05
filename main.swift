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
    get { resolveLang(saved: defaults.string(forKey: "lang"), preferred: Locale.preferredLanguages) }
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
var openAfterCreate: Bool {
    get { defaults.object(forKey: "openAfterCreate") as? Bool ?? false }
    set { defaults.set(newValue, forKey: "openAfterCreate") }
}
// Быстрые клавиши форматов: расширение ("" — папка) → [код клавиши, модификаторы]
var formatKeys: [String: [Int]] {
    get { defaults.dictionary(forKey: "formatKeys") as? [String: [Int]] ?? [:] }
    set { defaults.set(newValue, forKey: "formatKeys") }
}
// Порядок и скрытые форматы ("" — папка); нет ключей — как раньше (см. FormatPrefs)
var formatOrder: [String] {
    get { defaults.stringArray(forKey: FormatPrefs.orderKey) ?? [] }
    set { defaults.set(newValue, forKey: FormatPrefs.orderKey) }
}
var hiddenFormats: [String] {
    get { defaults.stringArray(forKey: FormatPrefs.hiddenKey) ?? [] }
    set { defaults.set(newValue, forKey: FormatPrefs.hiddenKey) }
}
func menuFormats() -> (all: [(format: Format, group: Int)], shown: [(format: Format, group: Int)]) {
    menuFormats(lang: lang, order: formatOrder, hidden: hiddenFormats, available: { $0.isEmpty || appFor($0) != nil })
}

// Окна Sparkle (и другие системные) — на языке Blankly: выбран в настройках — он, не выбран — как в системе.
// Действует со следующего запуска окна Sparkle; поэтому вызываем и при старте, и при смене языка.
func applyLanguage() {
    if let chosen = defaults.string(forKey: "lang") { defaults.set([chosen], forKey: "AppleLanguages") }
    else { defaults.removeObject(forKey: "AppleLanguages") }
}
func L(_ k: String) -> String { L(k, lang) }
func formatGroups() -> [[Format]] { formatGroups(lang: lang) }

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

// Свои шаблоны: любой файл или папка в этой папке появляется в меню, новый файл — его копия.
let userTemplatesDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Blankly/Templates", isDirectory: true)

func isFolder(_ url: URL) -> Bool { (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }

func userTemplates() -> [URL] {
    let items = (try? FileManager.default.contentsOfDirectory(
        at: userTemplatesDir, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
    return items
        .filter {
            let r = try? $0.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
            return r?.isDirectory == true || (r?.isRegularFile == true && !$0.pathExtension.isEmpty)
        }
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

// Имя из поля ввода → безопасное имя файла без расширения
func cleanBase(_ typed: String, ext: String, fallback: String) -> String {
    var s = typed.trimmingCharacters(in: .whitespacesAndNewlines)
    if !ext.isEmpty, s.lowercased().hasSuffix("." + ext) { s = String(s.dropLast(ext.count + 1)) }
    s = s.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    while s.hasPrefix(".") { s.removeFirst() } // не делаем скрытые файлы
    return s.isEmpty ? fallback : s
}

// template — свой шаблон пользователя (файл или папка; {date}, {time}, {name} подставляются)
func create(ext: String, base: String, in dir: URL, template: URL? = nil) -> URL? {
    let fm = FileManager.default
    let url = freeURL(in: dir, base: base, ext: ext)
    do {
        if let template {
            try copyTemplate(from: template, to: url, name: base)
        } else if ext.isEmpty {
            try fm.createDirectory(at: url, withIntermediateDirectories: false)
        } else if let tpl = Bundle.main.url(forResource: "empty", withExtension: ext, subdirectory: "templates") {
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
func formatTitle(_ ext: String) -> String { formatTitle(ext, lang: lang) }

func shortcutConflict(code: UInt32, mods: UInt32, owner: String) -> String? {
    shortcutConflict(code: code, mods: mods, owner: owner, menu: (hotKeyCode, hotKeyMods), formatKeys: formatKeys,
                     symbolic: UserDefaults(suiteName: "com.apple.symbolichotkeys")?.dictionary(forKey: "AppleSymbolicHotKeys"), lang: lang)
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
            if raw == "clipboard" { // буфер читаем здесь: у расширения Finder в песочнице доступа к нему может не быть
                targetDir = dir
                clickPoint = NSEvent.mouseLocation
                NSApp.activate(ignoringOtherApps: true)
                pasteFromClipboard()
                continue
            }
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
        var lastGroup: Int?
        for (f, group) in menuFormats().shown {
            if let g = lastGroup, g != group { menu.addItem(.separator()) }
            lastGroup = group
            let icon = f.ext.isEmpty ? NSWorkspace.shared.icon(for: .folder)
                : UTType(filenameExtension: f.ext).map { NSWorkspace.shared.icon(for: $0) }
            let it = item(f.title, ext: f.ext, icon: icon)
            showShortcut(of: f.ext, on: it)
            menu.addItem(it)
        }
        let mine = userTemplates().filter { isFolder($0) || appFor($0.pathExtension) != nil }
        if !mine.isEmpty {
            menu.addItem(.separator())
            let h = NSMenuItem(title: L("myTemplates"), action: nil, keyEquivalent: "")
            h.isEnabled = false
            menu.addItem(h)
            for t in mine {
                let it = item(isFolder(t) ? t.lastPathComponent : t.deletingPathExtension().lastPathComponent + " (.\(t.pathExtension))",
                              ext: t.pathExtension, icon: NSWorkspace.shared.icon(forFile: t.path))
                it.representedObject = t
                menu.addItem(it)
            }
        }
        if clipboardContent() != nil {
            menu.addItem(.separator())
            let c = item(L("fromClip"), ext: "", icon: NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil))
            c.representedObject = "clipboard"
            menu.addItem(c)
        }
        menu.addItem(.separator())
        let s = NSMenuItem(title: L("settings"), action: #selector(openSettings), keyEquivalent: "")
        s.target = self
        menu.addItem(s)
        let u = NSMenuItem(title: L("checkNow"), action: #selector(openUpdate), keyEquivalent: "")
        u.target = self
        menu.addItem(u)
        menu.addItem(.separator())
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

    // Сочетание формата справа от пункта (только буквы и цифры: их macOS умеет показать в меню)
    func showShortcut(of ext: String, on it: NSMenuItem) {
        guard let k = formatKeys[ext], k.count == 2, let key = keyNames[k[0]], key.count == 1,
              key.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) }) else { return }
        let m = UInt32(k[1])
        var flags: NSEvent.ModifierFlags = []
        if m & UInt32(controlKey) != 0 { flags.insert(.control) }
        if m & UInt32(optionKey) != 0 { flags.insert(.option) }
        if m & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if m & UInt32(cmdKey) != 0 { flags.insert(.command) }
        it.keyEquivalent = key.lowercased()
        it.keyEquivalentModifierMask = flags
    }

    func name(of dir: URL) -> String { isDesktop(dir) ? L("desktop") : dir.lastPathComponent }

    @objc func pick(_ sender: NSMenuItem) {
        // representedObject: расширение (встроенный формат, "" — папка) или URL своего шаблона
        if sender.representedObject as? String == "clipboard" { pasteFromClipboard(); return }
        let template = sender.representedObject as? URL
        guard let ext = template.map({ isFolder($0) ? "" : $0.pathExtension }) ?? sender.representedObject as? String else { return }
        var fallback = ext.isEmpty ? L("folder") : L("base")
        if let template { // имя шаблона с датой и временем — подсказка в окне имени
            let hint = fillVars(template.deletingPathExtension().lastPathComponent, name: "").trimmingCharacters(in: .whitespaces)
            if !hint.isEmpty { fallback = isFolder(template) ? fillVars(template.lastPathComponent, name: "").trimmingCharacters(in: .whitespaces) : hint }
        }
        guard let base = askName(ext: ext, fallback: fallback) else { return }
        if let url = create(ext: ext, base: base, in: targetDir, template: template) {
            reveal(url)
        } else {
            NSSound.beep()
            let a = NSAlert()
            a.messageText = String(format: L("failTitle"), base)
            a.informativeText = L("failText")
            a.runModal()
        }
    }

    // Созданное выделяем; если включено «открывать сразу» — файл ещё и открывается в программе по умолчанию
    // (нечем открыть — просто остаётся выделенным; папка всегда только выделяется)
    func reveal(_ url: URL) {
        select(url)
        if openAfterCreate, !isFolder(url), NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
        }
    }

    // Что лежит в буфере: текст → .txt/.json/.html, картинка → .png
    func clipboardContent() -> (ext: String, data: Data)? {
        let pb = NSPasteboard.general
        if let text = pb.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (clipboardExt(text: text), Data(text.utf8))
        }
        if let png = pb.data(forType: .png) { return ("png", png) }
        if let tiff = pb.data(forType: .tiff), let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            return ("png", png)
        }
        return nil
    }

    func pasteFromClipboard() {
        guard let clip = clipboardContent() else { NSSound.beep(); return }
        guard let base = askName(ext: clip.ext, fallback: L("clipName")) else { return }
        let url = freeURL(in: targetDir, base: base, ext: clip.ext)
        do {
            try clip.data.write(to: url, options: .withoutOverwriting)
            reveal(url)
        } catch {
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

final class SettingsWindow: NSObject, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    let app: App
    let window: NSWindow
    let hotLabel = NSTextField(labelWithString: "")
    let langLabel = NSTextField(labelWithString: "")
    let hotButton = NSButton()
    let note = NSTextField(labelWithString: "")
    let langPopup = NSPopUpButton()
    let loginBox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let updatesBox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let openBox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let finderLabel = NSTextField(labelWithString: "")
    let finderButton = NSButton()
    let version = NSTextField(labelWithString: "")
    let templatesButton = NSButton()
    let templatesHint = NSTextField(labelWithString: "")
    let fmtLabel = NSTextField(labelWithString: "")
    let fmtButton = NSButton()
    var monitor: Any?
    var recording: (owner: String, button: NSButton, note: NSTextField)?
    // окно «Форматы»
    var fmtWindow: NSWindow?
    let fmtNote = NSTextField(labelWithString: "")
    let fmtHint = NSTextField(labelWithString: "")
    var fmtButtons: [String: NSButton] = [:]
    var fmtTable: NSTableView?
    var fmtRows: [(format: Format, group: Int)] = []
    let fmtDragType = NSPasteboard.PasteboardType("app.blankly.format")

    init(app: App) {
        self.app = app
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 424),
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
        for l in supportedLangs {
            langPopup.addItem(withTitle: l.name)
            langPopup.lastItem?.representedObject = l.code
        }
        langPopup.target = self; langPopup.action = #selector(changeLang)

        loginBox.frame = NSRect(x: 20, y: 202, width: 340, height: 20)
        loginBox.target = self; loginBox.action = #selector(toggleLogin)
        updatesBox.frame = NSRect(x: 20, y: 172, width: 340, height: 20)
        updatesBox.target = self; updatesBox.action = #selector(toggleUpdates)
        openBox.frame = NSRect(x: 20, y: 172, width: 340, height: 20)
        openBox.target = self; openBox.action = #selector(toggleOpenAfter)
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

        [hotLabel, hotButton, note, fmtLabel, fmtButton, langLabel, langPopup, loginBox, updatesBox, openBox, finderLabel, finderButton, templatesButton, templatesHint, version]
            .forEach { v.addSubview($0) }
        // окно выросло на строку под «Открывать сразу»: всё от «Проверять обновления» и выше сдвигаем вверх
        v.subviews.filter { $0.frame.minY >= 172 && $0 !== openBox }.forEach { $0.frame.origin.y += 30 }
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
        openBox.title = L("openAfter")
        openBox.state = openAfterCreate ? .on : .off
        templatesButton.title = L("templatesBtn")
        templatesHint.stringValue = L("templatesHint")
        hotButton.title = shortcutText(code: hotKeyCode, mods: hotKeyMods)
        langPopup.selectItem(at: supportedLangs.firstIndex { $0.code == lang } ?? 0)
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

    // MARK: окно «Форматы»: папка и форматы, которые есть чем открыть — показ, порядок, клавиша, программа

    @objc func showFormatKeys() {
        if fmtWindow == nil { buildFormatWindow() }
        fmtWindow?.title = L("fmtTitle")
        fmtHint.stringValue = L("fmtHint")
        fmtNote.stringValue = ""
        fmtRows = menuFormats().all
        fmtTable?.reloadData()
        fmtWindow?.center()
        fmtWindow?.makeKeyAndOrderFront(nil)
    }

    func buildFormatWindow() {
        fmtRows = menuFormats().all
        let h = CGFloat(min(fmtRows.count, 14) * 30 + 28 + 100)
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: h), styleMask: [.titled, .closable],
                         backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.delegate = self
        let v = w.contentView!
        fmtHint.frame = NSRect(x: 20, y: h - 50, width: 740, height: 34)
        fmtHint.font = .systemFont(ofSize: 11); fmtHint.textColor = .secondaryLabelColor
        v.addSubview(fmtHint)

        let table = NSTableView()
        for (id, title, width) in [("show", L("colShow"), 80), ("name", L("base"), Int(fmtNameColumnWidth)), ("key", L("colKey"), 160), ("open", L("colOpen"), Int(fmtOpenColumnWidth))] {
            let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            c.title = title; c.width = CGFloat(width); c.resizingMask = []
            table.addTableColumn(c)
        }
        table.rowHeight = 30
        table.allowsColumnReordering = false
        table.allowsColumnResizing = false
        table.allowsMultipleSelection = false
        table.usesAlternatingRowBackgroundColors = true
        table.dataSource = self; table.delegate = self
        table.registerForDraggedTypes([fmtDragType])
        table.setDraggingSourceOperationMask(.move, forLocal: true)
        table.draggingDestinationFeedbackStyle = .gap
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 44, width: 740, height: h - 100))
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        v.addSubview(scroll)

        fmtNote.frame = NSRect(x: 20, y: 16, width: 740, height: 16)
        fmtNote.font = .systemFont(ofSize: 11); fmtNote.textColor = .systemRed
        v.addSubview(fmtNote)
        fmtTable = table
        fmtWindow = w
    }

    func numberOfRows(in tableView: NSTableView) -> Int { fmtRows.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        guard row < fmtRows.count else { return nil }
        let f = fmtRows[row].format
        let id = NSUserInterfaceItemIdentifier(f.ext)
        switch column?.identifier.rawValue {
        case "show":
            let b = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleShown(_:)))
            b.identifier = id
            b.state = hiddenFormats.contains(f.ext) ? .off : .on
            b.setAccessibilityLabel(f.title)
            let cell = NSView()
            b.frame = NSRect(x: 30, y: 5, width: 20, height: 20)
            cell.addSubview(b)
            return cell
        case "name":
            let cell = NSView()
            let t = NSTextField(labelWithString: f.title)
            t.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(t)
            NSLayoutConstraint.activate([t.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                                         t.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor),
                                         t.centerYAnchor.constraint(equalTo: cell.centerYAnchor)])
            return cell
        case "key":
            let cell = NSView()
            let b = NSButton(frame: NSRect(x: 0, y: 1, width: 124, height: 28))
            b.bezelStyle = .rounded
            b.identifier = id
            b.target = self; b.action = #selector(record(_:))
            b.setAccessibilityLabel("\(f.title): \(L("colKey"))")
            let x = NSButton(frame: NSRect(x: 126, y: 3, width: 26, height: 24))
            x.bezelStyle = .inline; x.isBordered = false
            x.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: L("fmtClear"))
            x.toolTip = L("fmtClear")
            x.identifier = id
            x.target = self; x.action = #selector(clearFormatKey(_:))
            cell.addSubview(b); cell.addSubview(x)
            fmtButtons[f.ext] = b
            refreshFormatKeys()
            return cell
        case "open":
            return f.ext.isEmpty ? NSView() : openPopup(for: f)
        default:
            return nil
        }
    }

    // «Открывать в…»: программы, которые умеют открывать тип; выбрана текущая по умолчанию
    func openPopup(for f: Format) -> NSView {
        let cell = NSView()
        let p = NSPopUpButton(frame: NSRect(x: 0, y: 2, width: fmtOpenColumnWidth - 8, height: 26), pullsDown: false)
        p.identifier = NSUserInterfaceItemIdentifier(f.ext)
        p.setAccessibilityLabel("\(f.title): \(L("colOpen"))")
        p.target = self; p.action = #selector(openChanged(_:))
        fillApps(p, ext: f.ext)
        cell.addSubview(p)
        return cell
    }

    func fillApps(_ p: NSPopUpButton, ext: String) {
        p.removeAllItems()
        guard let type = UTType(filenameExtension: ext) else { return }
        var apps = NSWorkspace.shared.urlsForApplications(toOpen: type)
        let cur = NSWorkspace.shared.urlForApplication(toOpen: type)
        if let cur, !apps.contains(cur) { apps.insert(cur, at: 0) }
        for u in apps {
            var name = FileManager.default.displayName(atPath: u.path)
            if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
            p.addItem(withTitle: name)
            p.lastItem?.representedObject = u
            p.lastItem?.toolTip = u.path
            let icon = NSWorkspace.shared.icon(forFile: u.path)
            icon.size = NSSize(width: 16, height: 16)
            p.lastItem?.image = icon
        }
        if let cur, let i = apps.firstIndex(of: cur) { p.selectItem(at: i) }
    }

    // macOS сама спрашивает подтверждение («Использовать …» / «Не изменять») и до ответа не вызывает completionHandler;
    // отказ приходит как ошибка — тогда возвращаем в списке прежнюю программу и говорим об этом.
    @objc func openChanged(_ p: NSPopUpButton) {
        if recording != nil { finish(nil) }
        let ext = p.identifier?.rawValue ?? ""
        guard let app = p.selectedItem?.representedObject as? URL, let type = UTType(filenameExtension: ext) else { return }
        fmtNote.stringValue = ""
        NSWorkspace.shared.setDefaultApplication(at: app, toOpen: type) { [weak self, weak p] err in
            DispatchQueue.main.async {
                guard let err, let self else { return }
                NSLog("Blankly: setDefaultApplication(.%@) failed: %@", ext, err.localizedDescription)
                self.fmtNote.stringValue = L("openFail")
                if let p { self.fillApps(p, ext: ext) }
            }
        }
    }

    @objc func toggleShown(_ b: NSButton) {
        let ext = b.identifier?.rawValue ?? ""
        var hidden = hiddenFormats
        if b.state == .on {
            hidden.removeAll { $0 == ext }
        } else {
            // скрыть всё нельзя
            if !fmtRows.contains(where: { $0.format.ext != ext && !hidden.contains($0.format.ext) }) {
                b.state = .on
                NSSound.beep()
                fmtNote.stringValue = L("fmtLast")
                return
            }
            if !hidden.contains(ext) { hidden.append(ext) }
        }
        fmtNote.stringValue = ""
        hiddenFormats = hidden
    }

    // Перетаскивание строк: порядок сразу пишется в defaults
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: fmtDragType)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
                   proposedDropOperation op: NSTableView.DropOperation) -> NSDragOperation {
        if op == .on { tableView.setDropRow(row, dropOperation: .above) }
        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        guard let s = info.draggingPasteboard.string(forType: fmtDragType), let from = Int(s), from < fmtRows.count else { return false }
        if recording != nil { finish(nil) }
        var rows = fmtRows
        let moved = rows.remove(at: from)
        rows.insert(moved, at: row > from ? row - 1 : row)
        fmtRows = rows
        formatOrder = rows.map { $0.format.ext }
        tableView.reloadData()
        return true
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
        lang = langPopup.selectedItem?.representedObject as? String ?? "en"
        applyLanguage()
        fmtWindow?.close(); fmtWindow = nil; fmtTable = nil; fmtButtons = [:] // пересоберётся на новом языке
        refresh()
    }

    @objc func openFinderExtensions() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc func toggleOpenAfter() { openAfterCreate = openBox.state == .on }

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
