import AppKit

// Ширина столбцов окна «Форматы» — расчётом по системному шрифту, без запуска приложения.
func testFormatColumns() {
    let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    func width(_ s: String) -> CGFloat { (s as NSString).size(withAttributes: [.font: font]).width }
    var longest: (String, CGFloat) = ("", 0)
    for code in supportedLangs.map({ $0.code }) {
        for f in formatGroups(lang: code).joined() + [Format(ext: "", title: L("folder", code))] where width(f.title) > longest.1 {
            longest = ("\(f.title) / \(code)", width(f.title))
        }
        check(width(L("base", code)) + 24 <= fmtNameColumnWidth, "заголовок «\(L("base", code))» (\(code)) шире столбца")
        for k in ["login", "checkUpdates", "openAfter", "renameFinder"] {
            check(width(L(k, code)) + 24 <= 340, "галка «\(L(k, code))» (\(code)) не влезает в окно настроек")
        }
        check(width(L("templatesBtn", code)) + 28 <= 186 && width(L("templatesChange", code)) + 28 <= 164, "кнопки шаблонов (\(code)) не влезают")
        // заголовки таблицы набраны шрифтом заголовка (мельче основного)
        let header = NSTableHeaderCell().font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let hw = (L("colShow", code) as NSString).size(withAttributes: [.font: header]).width
        check(hw + 16 <= fmtShowColumnWidth, "заголовок «\(L("colShow", code))» (\(code), \(Int(hw)) pt) шире столбца «Показывать»")
    }
    check(longest.1 + 16 <= fmtNameColumnWidth, "название «\(longest.0)» (\(Int(longest.1)) pt) не влезает в столбец \(Int(fmtNameColumnWidth))")
    // «Открывать в…»: значок 16 + отступ 6 + текст + стрелки меню ~30 + поля ~12
    let app = width("Microsoft PowerPoint") + 16 + 6 + 30 + 12
    check(app <= fmtOpenColumnWidth - 8, "«Microsoft PowerPoint» (\(Int(app)) pt) не влезает в список программ \(Int(fmtOpenColumnWidth - 8))")
    // все столбцы вместе влезают в окно на экране 1280
    check(80 + fmtNameColumnWidth + fmtKeyColumnWidth + fmtOpenColumnWidth + 80 <= 1280, "окно «Форматы» шире экрана 1280")
    // столбцы (с промежутками ~3 pt) влезают в таблицу шириной 740 без полосы прокрутки ~15
    // проверено глазами: при сумме 690 списки «Открывать в…» целиком, при 698 их правый край обрезан
    check(fmtShowColumnWidth + fmtNameColumnWidth + fmtKeyColumnWidth + fmtOpenColumnWidth <= 692, "столбцы шире таблицы в окне «Форматы»")
    print("fmt: самое длинное название — \(longest.0), \(Int(longest.1)) pt из \(Int(fmtNameColumnWidth)); программа — \(Int(app)) из \(Int(fmtOpenColumnWidth - 8))")
}
