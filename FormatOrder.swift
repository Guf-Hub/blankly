// Порядок и скрытие форматов. Отдельный файл без глобальных let: его компилируют приложение,
// расширение Finder (оно видит только свой файл и не может подключить Core.swift) и тесты.
import Foundation

enum FormatPrefs {
    // Ключи в defaults «app.blankly»: оба — массивы расширений, "" — «Новая папка»
    static let orderKey = "formatOrder"
    static let hiddenKey = "hiddenFormats"

    // exts — доступные форматы в порядке по умолчанию.
    // ordered — все они в сохранённом порядке (новые, которых там нет, — в конце, как были);
    // shown — без скрытых. Скрыть всё нельзя: если скрыто всё, показываем все.
    static func apply(_ exts: [String], order: [String], hidden: [String]) -> (ordered: [String], shown: [String]) {
        var ordered: [String] = []
        for e in order where exts.contains(e) && !ordered.contains(e) { ordered.append(e) }
        for e in exts where !ordered.contains(e) { ordered.append(e) }
        let shown = ordered.filter { !hidden.contains($0) }
        return (ordered, shown.isEmpty ? ordered : shown)
    }
}
