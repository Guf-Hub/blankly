import Foundation

// Каждый шаблон — корректный zip с главной частью документа.
func testTemplates(dir: String) {
    let required: [String: [String]] = [
        "docx": ["word/document.xml", "[Content_Types].xml"],
        "xlsx": ["xl/workbook.xml", "[Content_Types].xml"],
        "pptx": ["ppt/presentation.xml", "[Content_Types].xml"],
        "pages": ["Index/Document.iwa", "Metadata/Properties.plist"],
        "numbers": ["Index/Document.iwa", "Metadata/Properties.plist"],
        "key": ["Index/Document.iwa", "Metadata/Properties.plist"],
        "odt": ["content.xml", "mimetype"],
        "ods": ["content.xml", "mimetype"],
        "odp": ["content.xml", "mimetype"],
    ]
    let mimes = ["odt": "application/vnd.oasis.opendocument.text",
                 "ods": "application/vnd.oasis.opendocument.spreadsheet",
                 "odp": "application/vnd.oasis.opendocument.presentation"]
    let found = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasPrefix("empty.") }
    check(!found.isEmpty, "в \(dir) нет шаблонов empty.*")
    // шаблон, которого нет в таблице ожиданий, — тоже провал: новый формат надо описать здесь
    for file in found {
        let ext = (file as NSString).pathExtension
        check(required[ext] != nil, "шаблон \(file) не описан в тесте")
    }
    for (ext, parts) in required {
        let path = "\(dir)/empty.\(ext)"
        check(FileManager.default.fileExists(atPath: path), "нет шаблона empty.\(ext)")
        let (status, listing) = run("/usr/bin/unzip", ["-tq", path])
        check(status == 0, "empty.\(ext): повреждённый zip (\(listing.trimmingCharacters(in: .whitespacesAndNewlines)))")
        let (_, names) = run("/usr/bin/unzip", ["-Z1", path])
        let entries = Set(names.split(separator: "\n").map(String.init))
        for part in parts { check(entries.contains(part), "empty.\(ext): нет части \(part)") }
        if let mime = mimes[ext] {
            let (_, text) = run("/usr/bin/unzip", ["-p", path, "mimetype"])
            eq(text, mime, "empty.\(ext): mimetype")
            // mimetype должен идти первым и без сжатия — так требует ODF
            check(names.split(separator: "\n").first == "mimetype", "empty.\(ext): mimetype не первая запись")
        }
    }
}

func run(_ tool: String, _ args: [String]) -> (Int32, String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: tool)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    try! p.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(decoding: data, as: UTF8.self))
}
