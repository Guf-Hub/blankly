import Foundation

func testFormatOrder() {
    let base = ["", "txt", "md", "docx"]
    // нет ключей — как раньше
    var r = FormatPrefs.apply(base, order: [], hidden: [])
    eq(r.ordered, base, "по умолчанию"); eq(r.shown, base, "всё видно")
    // свой порядок; новый формат (docx) встаёт за своим соседом по умолчанию (md)
    r = FormatPrefs.apply(base, order: ["md", "", "txt"], hidden: [])
    eq(r.ordered, ["md", "docx", "", "txt"], "порядок")
    // новый формат из новой версии: rtf за txt, даже если пользователь всё переставил
    r = FormatPrefs.apply(["", "txt", "rtf", "md"], order: ["md", "txt", ""], hidden: [])
    eq(r.ordered, ["md", "txt", "rtf", ""], "rtf за txt")
    // у нового формата нет соседа в списке — в конец
    r = FormatPrefs.apply(["new", "txt"], order: ["txt"], hidden: [])
    eq(r.ordered, ["txt", "new"], "без соседа — в конец")
    // в порядке есть то, чего больше нет, и повторы — игнорируем
    r = FormatPrefs.apply(base, order: ["pdf", "md", "md"], hidden: [])
    eq(r.ordered, ["md", "docx", "", "txt"], "лишнее и дубли")
    // скрытие
    r = FormatPrefs.apply(base, order: ["md"], hidden: ["docx", ""])
    eq(r.shown, ["md", "txt"], "скрыты docx и папка"); eq(r.ordered.count, 4, "скрытые остаются в списке")
    // скрыть всё нельзя
    r = FormatPrefs.apply(base, order: [], hidden: base)
    eq(r.shown, base, "всё скрыто → показаны все")
    // скрыто только то, чего нет среди доступных
    r = FormatPrefs.apply(["txt"], order: [], hidden: ["txt", "docx"])
    eq(r.shown, ["txt"], "единственный не скрывается")

    // меню целиком: по умолчанию папка первой, группы как были
    let all = menuFormats(lang: "en", order: [], hidden: [], available: { _ in true })
    eq(all.shown.first?.format.ext ?? "?", "", "папка первая"); eq(all.shown.map { $0.group }.first ?? -1, 0, "группа папки")
    eq(all.shown.count, 1 + formatGroups(lang: "en").joined().count, "все форматы")
    // docx скрыт, md первым; формат без программы выпадает
    let m = menuFormats(lang: "ru", order: ["md"], hidden: ["docx"], available: { $0 != "xlsx" })
    eq(m.shown.first?.format.ext ?? "?", "md", "md первым")
    check(!m.shown.contains { $0.format.ext == "docx" }, "docx скрыт")
    check(!m.shown.contains { $0.format.ext == "xlsx" }, "xlsx без программы")
    check(m.all.contains { $0.format.ext == "docx" }, "docx остаётся в настройках")
}

// Форматы для кода скрыты по умолчанию; включённые запоминаются, остальные настройки не трогаются
func testDefaultHidden() {
    let all = FormatList.groups(text: "Text").joined().map(\.ext)
    for e in FormatList.hiddenByDefault { check(all.contains(e), "скрытый по умолчанию \(e) есть в списке форматов") }
    eq(Set(FormatPrefs.hidden(stored: [], shown: [])), Set(FormatList.hiddenByDefault), "новый пользователь: скрыты только форматы кода")
    eq(FormatPrefs.hidden(stored: ["docx"], shown: ["sh"]).contains("sh"), false, "включённый sh показан")
    eq(FormatPrefs.hidden(stored: ["docx"], shown: ["sh"]).contains("docx"), true, "своё скрытое осталось")
    eq(FormatPrefs.hidden(stored: ["sh"], shown: []).filter { $0 == "sh" }.count, 1, "без повторов")
    let m = menuFormats(lang: "en", order: [], hidden: FormatPrefs.hidden(stored: [], shown: []), available: { _ in true })
    check(!m.shown.contains { $0.format.ext == "php" }, "php не в меню по умолчанию")
    check(m.all.contains { $0.format.ext == "php" }, "php есть в окне «Форматы»")
    check(m.shown.contains { $0.format.ext == "py" }, "py в меню, как раньше")
    // скрипты: строка #! и право на запуск; xml — с объявлением
    for e in FormatList.executable { check(FormatList.starter(e)?.hasPrefix("#!") == true, "\(e) начинается с #!") }
    check(FormatList.starter("xml")?.hasPrefix("<?xml") == true, "xml начинается с объявления")
}
