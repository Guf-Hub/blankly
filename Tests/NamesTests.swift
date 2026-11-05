import Foundation

func testNames() {
    withTempDir { dir in
        func touch(_ name: String) { FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: Data()) }
        func mkdir(_ name: String) { try! FileManager.default.createDirectory(at: dir.appendingPathComponent(name), withIntermediateDirectories: false) }
        func free(_ base: String, _ ext: String) -> String { freeURL(in: dir, base: base, ext: ext).lastPathComponent }

        eq(free("Notes", "txt"), "Notes.txt", "свободное имя не меняется")
        touch("Notes.txt")
        eq(free("Notes", "txt"), "Notes 1.txt", "первое занято")
        touch("Notes 1.txt")
        eq(free("Notes", "txt"), "Notes 2.txt", "заняты первое и «1»")
        eq(free("Notes", "md"), "Notes.md", "другое расширение свободно")

        // дыра в нумерации: берём самый маленький свободный номер
        touch("Gap.txt"); touch("Gap 2.txt")
        eq(free("Gap", "txt"), "Gap 1.txt", "дыра в нумерации")

        // папка: без расширения и без точки
        eq(free("Docs", ""), "Docs", "папка свободна")
        mkdir("Docs")
        eq(free("Docs", ""), "Docs 1", "папка занята")
        mkdir("Docs 1")
        eq(free("Docs", ""), "Docs 2", "папки «Docs», «Docs 1» заняты")

        // имя уже кончается на цифру: к нему просто добавляется « 1»
        touch("Report 2024.txt")
        eq(free("Report 2024", "txt"), "Report 2024 1.txt", "имя кончается на цифру")
        touch("Report 2024 1.txt")
        eq(free("Report 2024", "txt"), "Report 2024 2.txt", "имя на цифру, второй круг")
        touch("Draft 1.txt")
        eq(free("Draft 1", "txt"), "Draft 1 1.txt", "«Draft 1» занято — «Draft 1 1»")

        // файл и папка с одним именем занимают одно место
        touch("Same")
        eq(free("Same", ""), "Same 1", "файл без расширения мешает папке")
    }
}
