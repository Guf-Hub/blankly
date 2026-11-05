import Foundation

// Языки берутся из типа таблицы: при добавлении языка в Lang/strings проверка расширяется сама.
func testStrings() {
    check(!strings.isEmpty, "таблица строк пуста")
    for (key, value) in strings {
        for (code, text) in languageValues(of: value) {
            check(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "строка «\(key)» пуста для языка \(code)")
        }
    }
    // L() отдаёт то, что лежит в таблице, и не падает ни на одном ключе
    for key in strings.keys {
        for code in ["ru", "en"] { check(!L(key, code).isEmpty, "L(\(key), \(code))") }
    }
    // форматные подстановки совпадают во всех языках (иначе String(format:) даст мусор)
    for (key, value) in strings {
        let counts = languageValues(of: value).map { $0.text.components(separatedBy: "%@").count - 1 }
        check(Set(counts).count == 1, "«\(key)»: число %@ различается между языками \(counts)")
    }
    // формат-группы: у каждого формата есть название на каждом языке
    for code in ["ru", "en"] {
        for f in formatGroups(lang: code).joined() { check(!f.title.isEmpty && !f.ext.isEmpty, "формат \(f.ext) / \(code)") }
    }
}

// Все языки значения через Mirror: метки кортежа (ru, en, …) — это и есть список языков.
func languageValues(of value: Any) -> [(code: String, text: String)] {
    Mirror(reflecting: value).children.compactMap { child in
        guard let label = child.label, let text = child.value as? String else { return nil }
        return (label, text)
    }
}
