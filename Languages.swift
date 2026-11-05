// Языки Blankly: список и выбор. Общий для приложения, расширения Finder и тестов.
import Foundation

// Код языка и его название на нём самом (так языки показаны в настройках).
let supportedLangs: [(code: String, name: String)] = [
    ("en", "English"), ("ru", "Русский"), ("de", "Deutsch"), ("fr", "Français"),
    ("es", "Español"), ("zh-Hans", "简体中文"), ("ja", "日本語"),
]

// Язык интерфейса: сохранённый в настройках (если поддерживаем), иначе первый поддерживаемый
// из языков системы, иначе английский. Китайский — только упрощённый (zh-Hans, zh-CN, zh-SG):
// традиционный (zh-Hant, zh-TW, zh-HK) пропускаем и смотрим следующий язык системы.
func resolveLang(saved: String?, preferred: [String]) -> String {
    if let saved, supportedLangs.contains(where: { $0.code == saved }) { return saved }
    for p in preferred {
        let id = p.lowercased().replacingOccurrences(of: "_", with: "-")
        if id == "zh" || id.hasPrefix("zh-hans") || id.hasPrefix("zh-cn") || id.hasPrefix("zh-sg") { return "zh-Hans" }
        if let code = supportedLangs.first(where: { $0.code != "zh-Hans" && ($0.code == id || id.hasPrefix($0.code + "-")) })?.code {
            return code
        }
    }
    return "en"
}
