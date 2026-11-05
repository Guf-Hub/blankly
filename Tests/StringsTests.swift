import Foundation

let allLangs = supportedLangs.map { $0.code }

func testStrings() {
    check(allLangs.count == 7, "ожидали 7 языков, а их \(allLangs.count)")
    check(translations["en"]?.isEmpty == false, "нет английской таблицы")
    let keys = Set(translations["en"]?.keys.map { $0 } ?? [])
    // у каждого языка из списка есть таблица, и в ней те же ключи, что в английской, с непустым текстом
    for code in allLangs {
        guard let table = translations[code] else { check(false, "нет таблицы для языка \(code)"); continue }
        check(Set(table.keys) == keys, "\(code): ключи не совпадают с en — нет \(keys.subtracting(table.keys).sorted()), лишние \(Set(table.keys).subtracting(keys).sorted())")
        for (key, text) in table { check(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "строка «\(key)» пуста для языка \(code)") }
    }
    check(Set(translations.keys) == Set(allLangs), "таблицы языков и supportedLangs расходятся")
    // форматные подстановки совпадают во всех языках (иначе String(format:) даст мусор)
    for key in keys {
        let counts = allLangs.map { (translations[$0]?[key] ?? "").components(separatedBy: "%@").count - 1 }
        check(Set(counts).count == 1, "«\(key)»: число %@ различается между языками \(counts)")
    }
    // L(): нет языка или ключа — английский, потом сам ключ
    check(L("create", "xx") == "Create", "неизвестный язык должен давать английский")
    check(L("no_such_key", "de") == "no_such_key", "неизвестный ключ — сам ключ")
    // формат-группы: у каждого формата есть название на каждом языке
    for code in allLangs {
        for f in formatGroups(lang: code).joined() { check(!f.title.isEmpty && !f.ext.isEmpty, "формат \(f.ext) / \(code)") }
    }
    // строки расширения Finder: те же 7 языков и те же ключи
    let extKeys = Set(FinderSync.strings["en"]?.keys.map { $0 } ?? [])
    check(!extKeys.isEmpty, "нет английских строк расширения")
    check(Set(FinderSync.strings.keys) == Set(allLangs), "языки расширения Finder расходятся с supportedLangs")
    for code in allLangs {
        let t = FinderSync.strings[code] ?? [:]
        check(Set(t.keys) == extKeys, "расширение, \(code): ключи не совпадают с en")
        for (k, v) in t { check(!v.isEmpty, "расширение, \(code): «\(k)» пусто") }
    }
}

func testLanguageChoice() {
    // сохранённый язык из 1.3.1 работает как раньше, остальное — язык системы
    check(resolveLang(saved: "ru", preferred: ["en-US"]) == "ru", "сохранённый ru")
    check(resolveLang(saved: "en", preferred: ["ru-RU"]) == "en", "сохранённый en")
    check(resolveLang(saved: "ja", preferred: ["ru-RU"]) == "ja", "сохранённый ja")
    check(resolveLang(saved: "klingon", preferred: ["de-DE"]) == "de", "неизвестный сохранённый → система")
    check(resolveLang(saved: nil, preferred: ["ru-RU", "en-US"]) == "ru", "русский мак")
    check(resolveLang(saved: nil, preferred: ["fr-CA"]) == "fr", "fr-CA → fr")
    check(resolveLang(saved: nil, preferred: ["es-419"]) == "es", "es-419 → es")
    check(resolveLang(saved: nil, preferred: ["pt-BR", "de-AT"]) == "de", "первый поддерживаемый из списка")
    check(resolveLang(saved: nil, preferred: ["zh-Hans-CN"]) == "zh-Hans", "zh-Hans-CN")
    check(resolveLang(saved: nil, preferred: ["zh-CN"]) == "zh-Hans", "zh-CN")
    check(resolveLang(saved: nil, preferred: ["zh-Hant-TW"]) == "en", "zh-Hant → en")
    check(resolveLang(saved: nil, preferred: ["zh-TW"]) == "en", "zh-TW → en")
    check(resolveLang(saved: nil, preferred: ["zh-HK", "ja-JP"]) == "ja", "традиционный китайский пропускаем")
    check(resolveLang(saved: nil, preferred: ["ja-JP"]) == "ja", "ja-JP")
    check(resolveLang(saved: nil, preferred: ["it-IT"]) == "en", "неподдерживаемый → en")
    check(resolveLang(saved: nil, preferred: []) == "en", "пусто → en")
}
