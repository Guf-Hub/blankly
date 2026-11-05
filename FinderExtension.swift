// Расширение Finder: кнопка на панели окна и «Новый файл ▸» в правом клике по пустому месту.
// Само ничего не создаёт (расширение живёт в песочнице) — передаёт Blankly папку и формат,
// а Blankly спрашивает имя и создаёт файл.
import Cocoa
import FinderSync
import UniformTypeIdentifiers

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    // Язык — из настроек Blankly (читать их разрешает entitlement в build.sh); не выбран — язык системы, как в приложении
    static var lang: String {
        resolveLang(saved: UserDefaults(suiteName: "app.blankly")?.string(forKey: "lang"), preferred: Locale.preferredLanguages)
    }

    // Строки расширения: язык → ключ → текст. Нет перевода — английский. Ключи проверяет Tests/StringsTests.swift.
    static let strings: [String: [String: String]] = [
        "en": ["text": "Text", "loText": "LibreOffice Text", "loCalc": "LibreOffice Spreadsheet", "loImpress": "LibreOffice Presentation",
               "newFile": "New File", "newFolder": "New Folder", "tip": "New file in this folder",
               "clipboard": "From Clipboard…", "more": "More… (my templates)"],
        "ru": ["text": "Текст", "loText": "LibreOffice Текст", "loCalc": "LibreOffice Таблица", "loImpress": "LibreOffice Презентация",
               "newFile": "Новый файл", "newFolder": "Новая папка", "tip": "Новый файл в этой папке",
               "clipboard": "Из буфера обмена…", "more": "Другое… (мои шаблоны)"],
        "de": ["text": "Text", "loText": "LibreOffice Text", "loCalc": "LibreOffice Tabelle", "loImpress": "LibreOffice Präsentation",
               "newFile": "Neue Datei", "newFolder": "Neuer Ordner", "tip": "Neue Datei in diesem Ordner",
               "clipboard": "Aus der Zwischenablage …", "more": "Weitere … (meine Vorlagen)"],
        "fr": ["text": "Texte", "loText": "LibreOffice Texte", "loCalc": "LibreOffice Tableur", "loImpress": "LibreOffice Présentation",
               "newFile": "Nouveau fichier", "newFolder": "Nouveau dossier", "tip": "Nouveau fichier dans ce dossier",
               "clipboard": "Depuis le presse-papiers…", "more": "Autres… (mes modèles)"],
        "es": ["text": "Texto", "loText": "LibreOffice Texto", "loCalc": "LibreOffice Hoja de cálculo", "loImpress": "LibreOffice Presentación",
               "newFile": "Nuevo archivo", "newFolder": "Nueva carpeta", "tip": "Nuevo archivo en esta carpeta",
               "clipboard": "Desde el portapapeles…", "more": "Más… (mis plantillas)"],
        "zh-Hans": ["text": "文本", "loText": "LibreOffice 文本", "loCalc": "LibreOffice 电子表格", "loImpress": "LibreOffice 演示文稿",
                    "newFile": "新建文件", "newFolder": "新建文件夹", "tip": "在此文件夹中新建文件",
                    "clipboard": "来自剪贴板…", "more": "更多…（我的模板）"],
        "ja": ["text": "テキスト", "loText": "LibreOffice テキスト", "loCalc": "LibreOffice スプレッドシート", "loImpress": "LibreOffice プレゼンテーション",
               "newFile": "新規ファイル", "newFolder": "新規フォルダ", "tip": "このフォルダに新規ファイル",
               "clipboard": "クリップボードから…", "more": "その他…（マイテンプレート）"],
    ]
    static func t(_ k: String) -> String { strings[lang]?[k] ?? strings["en"]?[k] ?? k }

    // (расширение, название); "folder" — новая папка. Тот же список, что в главном меню Blankly.
    static var formats: [[(String, String)]] { [
        [("txt", "\(t("text")) (.txt)"), ("md", "Markdown (.md)"), ("json", "JSON (.json)"),
         ("csv", "CSV (.csv)"), ("html", "HTML (.html)"), ("py", "Python (.py)")],
        [("docx", "Word (.docx)"), ("xlsx", "Excel (.xlsx)"), ("pptx", "PowerPoint (.pptx)")],
        [("odt", "\(t("loText")) (.odt)"), ("ods", "\(t("loCalc")) (.ods)"), ("odp", "\(t("loImpress")) (.odp)")],
    ] }
    static let allExts = formats.flatMap { $0.map { $0.0 } }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // Кнопка на панели окна Finder (добавляется через «Вид → Настроить панель инструментов»)
    override var toolbarItemName: String { "Blankly" }
    override var toolbarItemToolTip: String { Self.t("tip") }
    override var toolbarItemImage: NSImage {
        let img = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "Blankly") ?? NSImage()
        img.isTemplate = true // на панели Finder сам красит под тему
        return img
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .toolbarItemMenu:
            return formatsMenu() // сразу список форматов
        case .contextualMenuForContainer:
            let menu = NSMenu()
            let item = NSMenuItem(title: Self.t("newFile"), action: nil, keyEquivalent: "")
            item.image = themed("doc.badge.plus")
            item.submenu = formatsMenu()
            menu.addItem(item)
            return menu
        default:
            return nil
        }
    }

    // Папка и форматы в порядке из настроек Blankly (formatOrder / hiddenFormats), скрытые и без программы — убраны.
    // Группы дают разделители, как в главном меню.
    func formatsMenu() -> NSMenu {
        let menu = NSMenu()
        let suite = UserDefaults(suiteName: "app.blankly")
        var items: [(ext: String, title: String, group: Int)] = [("", Self.t("newFolder"), 0)]
        for (i, g) in Self.formats.enumerated() { items += g.map { ($0.0, $0.1, i + 1) } }
        items = items.filter { $0.ext.isEmpty || canOpen($0.ext) }
        let r = FormatPrefs.apply(items.map { $0.ext },
                                  order: suite?.stringArray(forKey: FormatPrefs.orderKey) ?? [],
                                  hidden: suite?.stringArray(forKey: FormatPrefs.hiddenKey) ?? [])
        var last: Int?
        for ext in r.shown {
            guard let it = items.first(where: { $0.ext == ext }) else { continue }
            if let g = last, g != it.group { menu.addItem(.separator()) }
            last = it.group
            menu.addItem(entry(it.title, tag: ext.isEmpty ? 0 : (Self.allExts.firstIndex(of: ext) ?? 0) + 1,
                               symbol: ext.isEmpty ? "folder" : nil))
        }
        let pb = NSPasteboard.general
        if pb.string(forType: .string) != nil || pb.data(forType: .png) != nil || pb.data(forType: .tiff) != nil {
            menu.addItem(.separator())
            menu.addItem(entry(Self.t("clipboard"), tag: -2, symbol: "doc.on.clipboard"))
        }
        menu.addItem(.separator())
        menu.addItem(entry(Self.t("more"), tag: -1, symbol: nil))
        return menu
    }

    func entry(_ title: String, tag: Int, symbol: String?) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: #selector(pick(_:)), keyEquivalent: "")
        it.tag = tag
        if let symbol { it.image = themed(symbol) }
        return it
    }

    func canOpen(_ ext: String) -> Bool {
        UTType(filenameExtension: ext).flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) } != nil
    }

    // Finder не перекрашивает значки в меню расширений под тему — красим сами.
    func themed(_ symbol: String) -> NSImage? {
        let dark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        let color: NSColor = dark ? NSColor(white: 1, alpha: 0.85) : NSColor(white: 0, alpha: 0.85)
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config)
    }

    // tag: 0 — папка, 1… — формат, -1 — полное меню Blankly (со своими шаблонами)
    @objc func pick(_ sender: NSMenuItem) {
        guard let dir = FIFinderSyncController.default().targetedURL() else { return }
        var q = [URLQueryItem(name: "path", value: dir.path)]
        if sender.tag == -2 { q.append(URLQueryItem(name: "ext", value: "clipboard")) }
        if sender.tag == 0 { q.append(URLQueryItem(name: "ext", value: "folder")) }
        if sender.tag > 0, sender.tag <= Self.allExts.count { q.append(URLQueryItem(name: "ext", value: Self.allExts[sender.tag - 1])) }
        var c = URLComponents()
        c.scheme = "blankly"
        c.host = "new"
        c.queryItems = q
        if let url = c.url { NSWorkspace.shared.open(url) }
    }
}
