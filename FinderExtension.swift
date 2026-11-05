// Расширение Finder: пункт «Новый файл…» в правом клике по пустому месту окна.
// Само ничего не создаёт (расширение живёт в песочнице) — просит Blankly показать меню для этой папки.
import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // Кнопка на панели окна Finder (добавляется через «Вид → Настроить панель инструментов»)
    override var toolbarItemName: String { "Blankly" }
    override var toolbarItemToolTip: String {
        Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "Новый файл в этой папке" : "New file in this folder"
    }
    override var toolbarItemImage: NSImage {
        let img = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "Blankly") ?? NSImage()
        img.isTemplate = true // на панели Finder сам красит под тему
        return img
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer || menuKind == .toolbarItemMenu else { return nil }
        let ru = Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let menu = NSMenu()
        let item = NSMenuItem(title: ru ? "Новый файл…" : "New File…", action: #selector(newFile(_:)), keyEquivalent: "")
        item.image = menuIcon()
        menu.addItem(item)
        return menu
    }

    // Finder не перекрашивает значки расширений под тему, поэтому красим сами:
    // в тёмной теме — светлый, в светлой — тёмный.
    func menuIcon() -> NSImage? {
        let dark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        let color: NSColor = dark ? NSColor(white: 1, alpha: 0.85) : NSColor(white: 0, alpha: 0.85)
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        return NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
    }

    @objc func newFile(_ sender: AnyObject?) {
        guard let dir = FIFinderSyncController.default().targetedURL() else { return }
        var c = URLComponents()
        c.scheme = "blankly"
        c.host = "new"
        c.queryItems = [URLQueryItem(name: "path", value: dir.path)]
        if let url = c.url { NSWorkspace.shared.open(url) }
    }
}
