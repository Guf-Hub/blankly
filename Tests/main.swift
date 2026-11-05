// Запуск: zsh test.sh. Аргумент 1 — папка Resources/templates.
import Foundation

let templatesDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/templates"
testNames()
testShortcuts()
testStrings()
testLanguageChoice()
testFormatOrder()
testCreation()
testTemplates(dir: templatesDir)

print(failures == 0 ? "OK: \(checks) проверок" : "FAILED: \(failures) из \(checks)")
exit(failures == 0 ? 0 : 1)
