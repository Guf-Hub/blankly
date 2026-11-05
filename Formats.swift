// Встроенные форматы по группам (группы дают разделители в меню). Один список на приложение и расширение Finder:
// файл без глобальных let, поэтому его можно компилировать и в расширение (см. FormatOrder.swift).
import Foundation

enum FormatList {
    // text — переведённое слово «Текст»
    static func groups(text: String) -> [[(ext: String, title: String)]] {
        [[("txt", "\(text) (.txt)"), ("rtf", "RTF (.rtf)"), ("md", "Markdown (.md)"), ("json", "JSON (.json)"),
          ("csv", "CSV (.csv)"), ("html", "HTML (.html)"), ("py", "Python (.py)")],
         [("docx", "Word (.docx)"), ("xlsx", "Excel (.xlsx)"), ("pptx", "PowerPoint (.pptx)")],
         [("pages", "Pages (.pages)"), ("numbers", "Numbers (.numbers)"), ("key", "Keynote (.key)")],
         [("odt", "LibreOffice Writer (.odt)"), ("ods", "LibreOffice Calc (.ods)"), ("odp", "LibreOffice Impress (.odp)")],
         [("sh", "Shell (.sh)"), ("rb", "Ruby (.rb)"), ("php", "PHP (.php)"), ("js", "JavaScript (.js)"),
          ("css", "CSS (.css)"), ("xml", "XML (.xml)"), ("yaml", "YAML (.yaml)"), ("swift", "Swift (.swift)"),
          ("tex", "LaTeX (.tex)")]]
    }

    // Скрыты, пока их не включат в окне «Форматы»: меню по умолчанию остаётся коротким
    static let hiddenByDefault = ["sh", "rb", "php", "js", "css", "xml", "yaml", "swift", "tex"]

    // Скрипты создаются с правом на запуск (chmod 755) и строкой #! в начале
    static let executable: Set<String> = ["sh", "py", "rb"]

    // Заготовка содержимого; nil — пустой файл (html и rtf заполняет приложение, офисные — из шаблонов)
    static func starter(_ ext: String) -> String? {
        switch ext {
        case "sh": return "#!/bin/bash\n\n"
        case "py": return "#!/usr/bin/env python3\n\n"
        case "rb": return "#!/usr/bin/env ruby\n\n"
        case "php": return "<?php\n\n"
        case "xml": return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        case "tex": return "\\documentclass{article}\n\\begin{document}\n\n\\end{document}\n"
        default: return nil
        }
    }
}
