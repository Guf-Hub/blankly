import Foundation

// Переменные шаблонов, копирование шаблонов-папок, расширение для текста из буфера.
func testCreation() {
    let now = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 14, minute: 30))!
    eq(fillVars("{date} {time} {name}", name: "Отчёт", now: now), "2026-11-05 14-30 Отчёт", "fillVars")
    eq(fillVars("без переменных {x}", name: "a", now: now), "без переменных {x}", "чужие скобки")

    // бинарные данные (нулевые байты, не utf-8) не меняются, даже если внутри есть {date}
    let bin = Data([0x50, 0x4B, 0x03, 0x04, 0x00, 0xFF]) + Data("{date}".utf8)
    check(fillData(bin, name: "x", now: now) == bin, "бинарные данные изменены")
    check(fillData(Data([0xFF, 0xFE, 0x7B]) + Data("{date}".utf8), name: "x", now: now).count == 9, "не-utf8 изменён")
    eq(String(decoding: fillData(Data("дата {date}".utf8), name: "x", now: now), as: UTF8.self), "дата 2026-11-05", "текст")

    withTempDir { dir in
        // файл: бинарный остаётся байт в байт
        let b = dir.appendingPathComponent("a.bin")
        try! bin.write(to: b)
        let b2 = dir.appendingPathComponent("b.bin")
        try! copyTemplate(from: b, to: b2, name: "x", now: now)
        check((try! Data(contentsOf: b2)) == bin, "копия бинарного файла изменилась")

        // папка: имена и текст внутри, вложенные папки, бинарный файл как есть
        let t = dir.appendingPathComponent("tpl")
        try! FileManager.default.createDirectory(at: t.appendingPathComponent("sub"), withIntermediateDirectories: true)
        try! Data("# {name} {date}".utf8).write(to: t.appendingPathComponent("{name}.md"))
        try! Data("{time}".utf8).write(to: t.appendingPathComponent("sub/notes {date}.txt"))
        try! bin.write(to: t.appendingPathComponent("img.bin"))
        let out = dir.appendingPathComponent("out")
        try! copyTemplate(from: t, to: out, name: "Проект", now: now)
        eq(try! String(contentsOf: out.appendingPathComponent("Проект.md"), encoding: .utf8), "# Проект 2026-11-05", "md в папке")
        eq(try! String(contentsOf: out.appendingPathComponent("sub/notes 2026-11-05.txt"), encoding: .utf8), "14-30", "вложенный файл")
        check((try! Data(contentsOf: out.appendingPathComponent("img.bin"))) == bin, "бинарный в папке изменился")
        // источник не тронут
        eq(try! String(contentsOf: t.appendingPathComponent("{name}.md"), encoding: .utf8), "# {name} {date}", "исходник")
    }

    eq(clipboardExt(text: "просто текст"), "txt", "txt")
    eq(clipboardExt(text: " {\"a\": [1, 2]}\n"), "json", "json объект")
    eq(clipboardExt(text: "[1,2,3]"), "json", "json массив")
    eq(clipboardExt(text: "{не json}"), "txt", "невалидный json")
    eq(clipboardExt(text: "42"), "txt", "число — не json")
    eq(clipboardExt(text: "<!DOCTYPE html><p>x"), "html", "doctype")
    eq(clipboardExt(text: "  <HTML lang=en>"), "html", "html")
    eq(clipboardExt(text: "<div>фрагмент</div>"), "txt", "фрагмент — txt")
}

// Ссылки в папке-шаблоне копируются как ссылки: нет петли и запись не уходит в чужой файл.
// Меню Finder и меню Blankly строятся из одного списка форматов.
func testTemplateLinksAndFormatList() {
    withTempDir { dir in
        let fm = FileManager.default
        let tpl = dir.appendingPathComponent("T"), outside = dir.appendingPathComponent("outside.txt")
        try! fm.createDirectory(at: tpl, withIntermediateDirectories: false)
        try! "{name}".write(to: outside, atomically: true, encoding: .utf8)
        try! fm.createSymbolicLink(at: tpl.appendingPathComponent("loop"), withDestinationURL: tpl)
        try! fm.createSymbolicLink(at: tpl.appendingPathComponent("link.txt"), withDestinationURL: outside)
        let out = dir.appendingPathComponent("Out")
        check((try? copyTemplate(from: tpl, to: out, name: "X")) != nil, "шаблон со ссылками копируется")
        eq((try? fm.destinationOfSymbolicLink(atPath: out.appendingPathComponent("loop").path)) ?? "", tpl.path, "петля осталась ссылкой")
        eq((try? String(contentsOf: outside, encoding: .utf8)) ?? "", "{name}", "файл за ссылкой не тронут")
    }
    eq(FinderSync.formats.map { $0.map(\.ext) }, formatGroups(lang: "en").map { $0.map(\.ext) }, "форматы Finder = форматы меню")
}
