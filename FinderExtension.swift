// Расширение Finder: кнопка на панели окна и «Новый файл ▸» в правом клике по пустому месту.
// Само ничего не создаёт (расширение живёт в песочнице) — передаёт Blankly папку и формат,
// а Blankly спрашивает имя и создаёт файл.
import Cocoa
import FinderSync
import UniformTypeIdentifiers

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    // Язык — из настроек Blankly (читать их разрешает entitlement в build.sh), иначе английский, как в приложении
    static var ru: Bool { UserDefaults(suiteName: "app.blankly")?.string(forKey: "lang") == "ru" }

    // (расширение, название); "folder" — новая папка. Тот же список, что в главном меню Blankly.
    static var formats: [[(String, String)]] { [
        [("txt", ru ? "Текст (.txt)" : "Text (.txt)"), ("md", "Markdown (.md)"), ("json", "JSON (.json)"),
         ("csv", "CSV (.csv)"), ("html", "HTML (.html)"), ("py", "Python (.py)")],
        [("docx", "Word (.docx)"), ("xlsx", "Excel (.xlsx)"), ("pptx", "PowerPoint (.pptx)")],
        [("odt", ru ? "LibreOffice Текст (.odt)" : "LibreOffice Text (.odt)"),
         ("ods", ru ? "LibreOffice Таблица (.ods)" : "LibreOffice Spreadsheet (.ods)"),
         ("odp", ru ? "LibreOffice Презентация (.odp)" : "LibreOffice Presentation (.odp)")],
    ] }
    static let allExts = formats.flatMap { $0.map { $0.0 } }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // Кнопка на панели окна Finder (добавляется через «Вид → Настроить панель инструментов»)
    override var toolbarItemName: String { "Blankly" }
    override var toolbarItemToolTip: String { Self.ru ? "Новый файл в этой папке" : "New file in this folder" }
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
            let item = NSMenuItem(title: Self.ru ? "Новый файл" : "New File", action: nil, keyEquivalent: "")
            item.image = themed("doc.badge.plus")
            item.submenu = formatsMenu()
            menu.addItem(item)
            return menu
        default:
            return nil
        }
    }

    func formatsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(entry(Self.ru ? "Новая папка" : "New Folder", tag: 0, symbol: "folder"))
        for group in Self.formats {
            let shown = group.filter { canOpen($0.0) }
            if shown.isEmpty { continue }
            menu.addItem(.separator())
            for (ext, title) in shown {
                menu.addItem(entry(title, tag: (Self.allExts.firstIndex(of: ext) ?? 0) + 1, symbol: nil))
            }
        }
        menu.addItem(.separator())
        menu.addItem(entry(Self.ru ? "Другое… (мои шаблоны)" : "More… (my templates)", tag: -1, symbol: nil))
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
        if sender.tag == 0 { q.append(URLQueryItem(name: "ext", value: "folder")) }
        if sender.tag > 0, sender.tag <= Self.allExts.count { q.append(URLQueryItem(name: "ext", value: Self.allExts[sender.tag - 1])) }
        var c = URLComponents()
        c.scheme = "blankly"
        c.host = "new"
        c.queryItems = q
        if let url = c.url { NSWorkspace.shared.open(url) }
    }
}
