// Встроенные форматы по группам (группы дают разделители в меню). Один список на приложение и расширение Finder:
// файл без глобальных let, поэтому его можно компилировать и в расширение (см. FormatOrder.swift).
import Foundation

enum FormatList {
    // text — переведённое слово «Текст»
    static func groups(text: String) -> [[(ext: String, title: String)]] {
        [[("txt", "\(text) (.txt)"), ("rtf", "RTF (.rtf)"), ("md", "Markdown (.md)"), ("json", "JSON (.json)"),
          ("csv", "CSV (.csv)"), ("html", "HTML (.html)"), ("py", "Python (.py)")],
         [("docx", "Word (.docx)"), ("xlsx", "Excel (.xlsx)"), ("pptx", "PowerPoint (.pptx)")],
         [("odt", "LibreOffice Writer (.odt)"), ("ods", "LibreOffice Calc (.ods)"), ("odp", "LibreOffice Impress (.odp)")]]
    }
}
