// Blankly — логика без интерфейса: имена, строки, сочетания клавиш. Подключается и к приложению, и к тестам (test.sh).
import AppKit
import Carbon.HIToolbox

// MARK: - Строки

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

func L(_ k: String, _ lang: String) -> String { let s = strings[k]!; return lang == "en" ? s.en : s.ru }

// MARK: - Форматы

struct Format { let ext: String; let title: String }
func formatGroups(lang: String) -> [[Format]] {
    [[Format(ext: "txt", title: "\(L("text", lang)) (.txt)"),
      Format(ext: "md", title: "Markdown (.md)"),
      Format(ext: "json", title: "JSON (.json)"),
      Format(ext: "csv", title: "CSV (.csv)"),
      Format(ext: "html", title: "HTML (.html)"),
      Format(ext: "py", title: "Python (.py)")],
     [Format(ext: "docx", title: "Word (.docx)"),
      Format(ext: "xlsx", title: "Excel (.xlsx)"),
      Format(ext: "pptx", title: "PowerPoint (.pptx)")],
     [Format(ext: "odt", title: "\(L("lo_text", lang)) (.odt)"),
      Format(ext: "ods", title: "\(L("lo_calc", lang)) (.ods)"),
      Format(ext: "odp", title: "\(L("lo_impress", lang)) (.odp)")]]
}

// Название формата для подсказок: "" — папка
func formatTitle(_ ext: String, lang: String) -> String {
    ext.isEmpty ? L("folder", lang) : formatGroups(lang: lang).joined().first(where: { $0.ext == ext })?.title ?? ext
}

// MARK: - Имена

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

// MARK: - Шаблоны: переменные

// {date} → 2026-11-05, {time} → 14-30, {name} → введённое имя
func fillVars(_ s: String, name: String, now: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    let date = f.string(from: now)
    f.dateFormat = "HH-mm"
    let time = f.string(from: now)
    return s.replacingOccurrences(of: "{date}", with: date)
        .replacingOccurrences(of: "{time}", with: time)
        .replacingOccurrences(of: "{name}", with: name)
}

// Содержимое файла-шаблона: текст в utf-8 (без нулевых байтов) подставляем, остальное — как есть
func fillData(_ data: Data, name: String, now: Date = Date()) -> Data {
    guard !data.contains(0), let text = String(data: data, encoding: .utf8) else { return data }
    return Data(fillVars(text, name: name, now: now).utf8)
}

// Копия шаблона (файл или папка целиком) в dst; в папке подставляем и имена внутри
func copyTemplate(from src: URL, to dst: URL, name: String, now: Date = Date()) throws {
    let fm = FileManager.default
    var isDir: ObjCBool = false
    fm.fileExists(atPath: src.path, isDirectory: &isDir)
    if isDir.boolValue {
        try fm.createDirectory(at: dst, withIntermediateDirectories: false)
        for item in try fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil) where item.lastPathComponent != ".DS_Store" {
            let child = fillVars(item.lastPathComponent, name: name, now: now).replacingOccurrences(of: "/", with: "-")
            try copyTemplate(from: item, to: dst.appendingPathComponent(child), name: name, now: now)
        }
    } else {
        try fm.copyItem(at: src, to: dst)
        let data = try Data(contentsOf: dst)
        let filled = fillData(data, name: name, now: now)
        if filled != data { try filled.write(to: dst) } // запись поверх сохраняет права файла
    }
}

// MARK: - Буфер обмена

// Расширение для текста из буфера: JSON-объект или массив → json, HTML-документ → html, иначе txt
func clipboardExt(text: String) -> String {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let head = t.prefix(15).lowercased()
    if head.hasPrefix("<!doctype") || head.hasPrefix("<html") { return "html" }
    if t.hasPrefix("{") || t.hasPrefix("["),
       (try? JSONSerialization.jsonObject(with: Data(t.utf8))) != nil { return "json" }
    return "txt"
}

// MARK: - Сочетания клавиш

func carbonMods(_ f: NSEvent.ModifierFlags) -> UInt32 {
    var m: UInt32 = 0
    if f.contains(.control) { m |= UInt32(controlKey) }
    if f.contains(.option) { m |= UInt32(optionKey) }
    if f.contains(.shift) { m |= UInt32(shiftKey) }
    if f.contains(.command) { m |= UInt32(cmdKey) }
    return m
}

// Включённое сочетание macOS из «Клавиатура → Сочетания клавиш» (скриншоты, Spotlight, язык ввода…).
// symbolic — словарь AppleSymbolicHotKeys; в тестах подставляем свой.
func systemShortcutTaken(code: UInt32, mods: UInt32, symbolic all: [String: Any]?) -> Bool {
    guard let all else { return false }
    for case let item as [String: Any] in all.values {
        guard (item["enabled"] as? Bool) == true,
              let p = (item["value"] as? [String: Any])?["parameters"] as? [Int], p.count == 3 else { continue }
        if UInt32(p[1]) == code && carbonMods(NSEvent.ModifierFlags(rawValue: UInt(p[2]))) == mods { return true }
    }
    return false
}

// Почему сочетание взять нельзя (nil — можно). owner — чьё сочетание меняем: "main" или расширение формата.
// Сочетания из меню других программ macOS узнать не даёт — поэтому для форматов требуем ⌃⌥.
func shortcutConflict(code: UInt32, mods: UInt32, owner: String, menu: (code: UInt32, mods: UInt32),
                      formatKeys: [String: [Int]], symbolic: [String: Any]?, lang: String) -> String? {
    if owner != "main" && code == menu.code && mods == menu.mods { return L("usedMenu", lang) }
    for (ext, k) in formatKeys where ext != owner && k == [Int(code), Int(mods)] {
        return String(format: L("usedFor", lang), formatTitle(ext, lang: lang))
    }
    if systemShortcutTaken(code: code, mods: mods, symbolic: symbolic) { return L("usedSystem", lang) }
    return nil
}
