// Порядок и скрытие форматов. Отдельный файл без глобальных let: его компилируют приложение,
// расширение Finder (оно видит только свой файл и не может подключить Core.swift) и тесты.
import Foundation

enum FormatPrefs {
    // Ключи в defaults «app.blankly»: оба — массивы расширений, "" — «Новая папка»
    static let orderKey = "formatOrder"
    static let hiddenKey = "hiddenFormats"

    // exts — доступные форматы в порядке по умолчанию.
    // ordered — все они в сохранённом порядке; новый формат, которого там нет (появился в новой версии),
    // встаёт сразу за своим соседом по умолчанию (RTF — за «Текстом»), а не в конец;
    // shown — без скрытых. Скрыть всё нельзя: если скрыто всё, показываем все.
    static func apply(_ exts: [String], order: [String], hidden: [String]) -> (ordered: [String], shown: [String]) {
        var ordered: [String] = []
        for e in order where exts.contains(e) && !ordered.contains(e) { ordered.append(e) }
        for (i, e) in exts.enumerated() where !ordered.contains(e) {
            // ближайший предыдущий по умолчанию, который уже стоит в списке
            if let prev = exts[..<i].last(where: { ordered.contains($0) }), let at = ordered.firstIndex(of: prev) {
                ordered.insert(e, at: at + 1)
            } else {
                ordered.append(e)
            }
        }
        let shown = ordered.filter { !hidden.contains($0) }
        return (ordered, shown.isEmpty ? ordered : shown)
    }
}
