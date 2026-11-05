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

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer else { return nil }
        let ru = Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let menu = NSMenu()
        let item = NSMenuItem(title: ru ? "Новый файл…" : "New File…", action: #selector(newFile(_:)), keyEquivalent: "")
        // template — Finder перекрашивает значок под светлую и тёмную тему
        let icon = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        icon?.isTemplate = true
        item.image = icon
        menu.addItem(item)
        return menu
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
