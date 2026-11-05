import Foundation
import Carbon.HIToolbox
import AppKit

func testShortcuts() {
    let ctrlOpt = UInt32(controlKey | optionKey)
    let menu = (code: UInt32(kVK_ANSI_N), mods: ctrlOpt)
    let formatKeys: [String: [Int]] = ["docx": [kVK_ANSI_W, Int(ctrlOpt)]]
    // Системное сочетание ⌃⌥J: parameters = [символ, код клавиши, флаги NSEvent]
    let flags = Int(NSEvent.ModifierFlags([.control, .option]).rawValue)
    let symbolic: [String: Any] = [
        "1": ["enabled": true, "value": ["parameters": [65535, kVK_ANSI_J, flags]]],
        "2": ["enabled": false, "value": ["parameters": [65535, kVK_ANSI_K, flags]]],
    ]
    func conflict(_ code: Int, owner: String, mods: UInt32? = nil, lang: String = "en", sys: [String: Any]? = symbolic) -> String? {
        shortcutConflict(code: UInt32(code), mods: mods ?? ctrlOpt, owner: owner, menu: menu,
                         formatKeys: formatKeys, symbolic: sys, lang: lang)
    }

    // меню Blankly: формату нельзя, самому меню — можно (оно меняет своё)
    eq(conflict(kVK_ANSI_N, owner: "txt"), L("usedMenu", "en"), "сочетание меню занято для формата")
    eq(conflict(kVK_ANSI_N, owner: "main"), nil, "меню своё сочетание не конфликтует")
    // другой формат
    eq(conflict(kVK_ANSI_W, owner: "txt"), String(format: L("usedFor", "en"), "Word (.docx)"), "занято другим форматом")
    eq(conflict(kVK_ANSI_W, owner: "docx"), nil, "свой формат не конфликтует")
    eq(conflict(kVK_ANSI_W, owner: "main"), String(format: L("usedFor", "en"), "Word (.docx)"), "меню против формата")
    // язык подставляется в текст
    check(conflict(kVK_ANSI_W, owner: "txt", lang: "ru")!.contains("Word"), "русский текст конфликта")
    eq(conflict(kVK_ANSI_N, owner: "txt", lang: "ru"), L("usedMenu", "ru"), "русский текст меню")
    // системное: включено — занято, выключено — свободно
    eq(conflict(kVK_ANSI_J, owner: "txt"), L("usedSystem", "en"), "системное включено")
    eq(conflict(kVK_ANSI_K, owner: "txt"), nil, "системное выключено")
    // свободное
    eq(conflict(kVK_ANSI_Q, owner: "txt"), nil, "свободное сочетание")
    // та же клавиша, но другие модификаторы — не конфликт
    eq(conflict(kVK_ANSI_J, owner: "txt", mods: UInt32(cmdKey)), nil, "другие модификаторы")
    // нет данных о системных — не падает и не мешает
    eq(conflict(kVK_ANSI_J, owner: "txt", sys: nil), nil, "нет системных сочетаний")
    // порядок проверок: меню важнее системного
    eq(shortcutConflict(code: UInt32(kVK_ANSI_J), mods: ctrlOpt, owner: "txt", menu: (UInt32(kVK_ANSI_J), ctrlOpt),
                        formatKeys: [:], symbolic: symbolic, lang: "en"), L("usedMenu", "en"), "порядок: меню раньше системного")

    eq(carbonMods([.control, .option]), ctrlOpt, "carbonMods ⌃⌥")
}
