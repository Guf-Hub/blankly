import Foundation

func testFormatOrder() {
    let base = ["", "txt", "md", "docx"]
    // нет ключей — как раньше
    var r = FormatPrefs.apply(base, order: [], hidden: [])
    eq(r.ordered, base, "по умолчанию"); eq(r.shown, base, "всё видно")
    // свой порядок; новые форматы (docx) — в конец
    r = FormatPrefs.apply(base, order: ["md", "", "txt"], hidden: [])
    eq(r.ordered, ["md", "", "txt", "docx"], "порядок")
    // в порядке есть то, чего больше нет, и повторы — игнорируем
    r = FormatPrefs.apply(base, order: ["pdf", "md", "md"], hidden: [])
    eq(r.ordered, ["md", "", "txt", "docx"], "лишнее и дубли")
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
