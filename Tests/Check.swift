// Мини-раннер без XCTest: check() считает провалы, main.swift выходит с кодом 1, если они есть.
import Foundation

var failures = 0
var checks = 0

func check(_ ok: Bool, _ what: @autoclosure () -> String, line: Int = #line, file: String = #file) {
    checks += 1
    if !ok {
        failures += 1
        print("FAIL \((file as NSString).lastPathComponent):\(line): \(what())")
    }
}

func eq<T: Equatable>(_ a: T, _ b: T, _ what: String = "", line: Int = #line, file: String = #file) {
    check(a == b, "\(what) ожидалось \(b), получено \(a)", line: line, file: file)
}

// Пустая временная папка, удаляется после блока
func withTempDir(_ body: (URL) -> Void) {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("blankly-test-\(UUID().uuidString)")
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    body(dir)
}
