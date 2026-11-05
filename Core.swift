// Blankly — логика без интерфейса: имена, строки, сочетания клавиш. Подключается и к приложению, и к тестам (test.sh).
import AppKit
import Carbon.HIToolbox

// MARK: - Строки

// Строки интерфейса: язык → ключ → текст. Английский — основной: ключи берутся из него, а если перевода нет, показывается он.
// Добавить язык: словарь ниже, строка в supportedLangs (Languages.swift), CFBundleLocalizations в build.sh.
// Переводы машинные, носителями языка не проверены.
let translations: [String: [String: String]] = [
    "en": [
        "base": "New File",
        "createIn": "Create in “%@”",
        "desktop": "Desktop",
        "folder": "New Folder",
        "settings": "Settings…",
        "quit": "Quit",
        "text": "Text",
        "askFolder": "Name of the new folder",
        "askFile": "Name of the new file",
        "askWhere": "Will be created in “%@”",
        "create": "Create",
        "cancel": "Cancel",
        "failTitle": "Couldn’t create “%@”",
        "failText": "You may not have permission to write to this folder.",
        "winTitle": "Blankly — Settings",
        "hotkey": "Shortcut:",
        "press": "Press shortcut…",
        "needMod": "Use ⌘, ⌃ or ⌥",
        "busy": "Shortcut is used by another app",
        "language": "Language:",
        "fmtKeys": "Formats:",
        "fmtSetup": "Set Up…",
        "fmtTitle": "Blankly — Formats",
        "fmtHint": "Drag rows to set the order. For a shortcut, click a field and press\na combination with ⌃⌥: the file is created right away, just type a name.",
        "fmtClear": "Remove shortcut",
        "needCtrlOpt": "Use ⌃ and ⌥ together",
        "usedMenu": "Already used: Blankly menu",
        "usedFor": "Already used: %@",
        "usedSystem": "Used by macOS: Settings → Keyboard",
        "login": "Open at login",
        "loginFail": "Couldn’t change login item",
        "myTemplates": "My Templates",
        "updateAvail": "Version %@ is available — update",
        "checkNow": "Check for Updates…",
        "finderRow": "Finder right-click: %@",
        "on": "on",
        "off": "off",
        "finderBtn": "Turn On…",
        "checkUpdates": "Check for updates daily",
        "templatesBtn": "Templates Folder…",
        "templatesHint": "Put any file there — it shows up in the menu\nand new files are copies of it.",
        // formats
        "colShow": "Show",
        "colKey": "Shortcut",
        "colOpen": "Open in…",
        "fmtLast": "At least one item must stay visible",
        "openFail": "App not changed: you declined in the macOS prompt or it was refused.",
        // creation
        "openAfter": "Open file right after creating",
        "fromClip": "From Clipboard…",
        "clipName": "From Clipboard",
        "renameFinder": "Don't ask for a name — rename in Finder",
        "templatesChange": "Change…",
        "tipTemplatesChange": "Pick another templates folder, for example in iCloud Drive. Your templates are copied there.",
        "tipRename": "Creates the file at once and starts renaming it in Finder. Needs the Accessibility permission.",
        "tipKey": "Click and press Control + Option + a key. The shortcut creates this file right away, without the menu.",
        "tipOpen": "The app macOS opens this file type with.",
    ],
    "ru": [
        "base": "Новый файл",
        "createIn": "Создать в «%@»",
        "desktop": "Рабочий стол",
        "folder": "Новая папка",
        "settings": "Настройки…",
        "quit": "Выйти",
        "text": "Текст",
        "askFolder": "Имя новой папки",
        "askFile": "Имя нового файла",
        "askWhere": "Будет создано в «%@»",
        "create": "Создать",
        "cancel": "Отмена",
        "failTitle": "Не удалось создать «%@»",
        "failText": "Возможно, в эту папку нельзя записывать.",
        "winTitle": "Blankly — настройки",
        "hotkey": "Сочетание клавиш:",
        "press": "Нажмите сочетание…",
        "needMod": "Нужна клавиша ⌘, ⌃ или ⌥",
        "busy": "Сочетание занято другой программой",
        "language": "Язык:",
        "fmtKeys": "Форматы:",
        "fmtSetup": "Настроить…",
        "fmtTitle": "Blankly — форматы",
        "fmtHint": "Перетащите строки, чтобы задать порядок. Для клавиши нажмите на поле\nи сочетание с ⌃⌥: файл создастся сразу, останется ввести имя.",
        "fmtClear": "Убрать сочетание",
        "needCtrlOpt": "Нужны ⌃ и ⌥ вместе",
        "usedMenu": "Уже занято: меню Blankly",
        "usedFor": "Уже занято: %@",
        "usedSystem": "Занято в macOS: Настройки → Клавиатура",
        "login": "Запускать при входе в систему",
        "loginFail": "Не удалось изменить автозапуск",
        "myTemplates": "Мои шаблоны",
        "updateAvail": "Доступна версия %@ — обновить",
        "checkNow": "Проверить обновления…",
        "finderRow": "Правый клик в Finder: %@",
        "on": "включён",
        "off": "выключен",
        "finderBtn": "Включить…",
        "checkUpdates": "Проверять обновления раз в день",
        "templatesBtn": "Папка шаблонов…",
        "templatesHint": "Положите туда любой файл — он появится в меню,\nа новый файл будет его копией.",
        // formats
        "colShow": "Показывать",
        "colKey": "Клавиша",
        "colOpen": "Открывать в…",
        "fmtLast": "Хотя бы один пункт должен остаться",
        "openFail": "Программа не изменена: вы отказались в окне macOS или она не разрешила.",
        // creation
        "openAfter": "Открывать файл сразу после создания",
        "fromClip": "Из буфера обмена…",
        "clipName": "Из буфера",
        "renameFinder": "Не спрашивать имя — переименовать в Finder",
        "templatesChange": "Изменить…",
        "tipTemplatesChange": "Выбрать другую папку для шаблонов, например в iCloud Drive. Шаблоны скопируются туда.",
        "tipRename": "Файл создаётся сразу, и Finder начинает его переименовывать. Нужно разрешение «Универсальный доступ».",
        "tipKey": "Нажмите и введите Control + Option + клавишу. Сочетание создаст этот файл сразу, без меню.",
        "tipOpen": "Программа, в которой macOS открывает этот тип файлов.",
    ],
    "de": [
        "base": "Neue Datei",
        "createIn": "In „%@“ erstellen",
        "desktop": "Schreibtisch",
        "folder": "Neuer Ordner",
        "settings": "Einstellungen …",
        "quit": "Beenden",
        "text": "Text",
        "askFolder": "Name des neuen Ordners",
        "askFile": "Name der neuen Datei",
        "askWhere": "Wird in „%@“ erstellt",
        "create": "Erstellen",
        "cancel": "Abbrechen",
        "failTitle": "„%@“ konnte nicht erstellt werden",
        "failText": "Möglicherweise haben Sie keine Schreibrechte für diesen Ordner.",
        "winTitle": "Blankly — Einstellungen",
        "hotkey": "Tastenkürzel:",
        "press": "Tastenkürzel drücken …",
        "needMod": "⌘, ⌃ oder ⌥ verwenden",
        "busy": "Tastenkürzel wird von einem anderen Programm verwendet",
        "language": "Sprache:",
        "fmtKeys": "Formate:",
        "fmtSetup": "Einrichten …",
        "fmtTitle": "Blankly — Formate",
        "fmtHint": "Zeilen ziehen, um die Reihenfolge festzulegen. Für ein Tastenkürzel ein Feld anklicken\nund ⌃⌥ mit einer Taste drücken: Die Datei wird sofort erstellt, nur der Name fehlt noch.",
        "fmtClear": "Tastenkürzel entfernen",
        "needCtrlOpt": "⌃ und ⌥ zusammen verwenden",
        "usedMenu": "Bereits belegt: Blankly-Menü",
        "usedFor": "Bereits belegt: %@",
        "usedSystem": "Von macOS belegt: Einstellungen → Tastatur",
        "login": "Beim Anmelden öffnen",
        "loginFail": "Anmeldeobjekt konnte nicht geändert werden",
        "myTemplates": "Meine Vorlagen",
        "updateAvail": "Version %@ verfügbar – aktualisieren",
        "checkNow": "Nach Updates suchen …",
        "finderRow": "Rechtsklick im Finder: %@",
        "on": "aktiviert",
        "off": "deaktiviert",
        "finderBtn": "Aktivieren …",
        "checkUpdates": "Täglich nach Updates suchen",
        "templatesBtn": "Vorlagenordner …",
        "templatesHint": "Legen Sie dort eine beliebige Datei ab – sie erscheint\nim Menü, neue Dateien sind Kopien davon.",
        // formats
        "colShow": "Anzeigen",
        "colKey": "Tastenkürzel",
        "colOpen": "Öffnen mit …",
        "fmtLast": "Mindestens ein Eintrag muss sichtbar bleiben",
        "openFail": "Programm nicht geändert: Die Änderung wurde im macOS-Dialog abgelehnt oder verweigert.",
        // creation
        "openAfter": "Datei nach dem Erstellen sofort öffnen",
        "fromClip": "Aus der Zwischenablage …",
        "clipName": "Aus Zwischenablage",
        "renameFinder": "Nicht nach Namen fragen — im Finder umbenennen",
        "templatesChange": "Ändern…",
        "tipTemplatesChange": "Einen anderen Vorlagenordner wählen, zum Beispiel in iCloud Drive. Ihre Vorlagen werden dorthin kopiert.",
        "tipRename": "Erstellt die Datei sofort und startet die Umbenennung im Finder. Benötigt die Berechtigung „Bedienungshilfen“.",
        "tipKey": "Klicken und Control + Option + eine Taste drücken. Der Kurzbefehl erstellt diese Datei sofort, ohne Menü.",
        "tipOpen": "Die App, mit der macOS diesen Dateityp öffnet.",
    ],
    "fr": [
        "base": "Nouveau fichier",
        "createIn": "Créer dans « %@ »",
        "desktop": "Bureau",
        "folder": "Nouveau dossier",
        "settings": "Réglages…",
        "quit": "Quitter",
        "text": "Texte",
        "askFolder": "Nom du nouveau dossier",
        "askFile": "Nom du nouveau fichier",
        "askWhere": "Sera créé dans « %@ »",
        "create": "Créer",
        "cancel": "Annuler",
        "failTitle": "Impossible de créer « %@ »",
        "failText": "Vous n’avez peut-être pas l’autorisation d’écrire dans ce dossier.",
        "winTitle": "Blankly — Réglages",
        "hotkey": "Raccourci :",
        "press": "Appuyez sur un raccourci…",
        "needMod": "Utilisez ⌘, ⌃ ou ⌥",
        "busy": "Raccourci utilisé par une autre app",
        "language": "Langue :",
        "fmtKeys": "Formats :",
        "fmtSetup": "Configurer…",
        "fmtTitle": "Blankly — Formats",
        "fmtHint": "Faites glisser les lignes pour définir l’ordre. Pour un raccourci, cliquez sur un champ\net appuyez sur ⌃⌥ avec une touche : le fichier est créé aussitôt, il reste à saisir le nom.",
        "fmtClear": "Supprimer le raccourci",
        "needCtrlOpt": "Utilisez ⌃ et ⌥ ensemble",
        "usedMenu": "Déjà utilisé : menu Blankly",
        "usedFor": "Déjà utilisé : %@",
        "usedSystem": "Utilisé par macOS : Réglages → Clavier",
        "login": "Ouvrir à l’ouverture de session",
        "loginFail": "Impossible de modifier l’élément d’ouverture",
        "myTemplates": "Mes modèles",
        "updateAvail": "La version %@ est disponible — mettre à jour",
        "checkNow": "Rechercher les mises à jour…",
        "finderRow": "Clic droit dans le Finder : %@",
        "on": "activé",
        "off": "désactivé",
        "finderBtn": "Activer…",
        "checkUpdates": "Rechercher les mises à jour chaque jour",
        "templatesBtn": "Dossier des modèles…",
        "templatesHint": "Placez-y n’importe quel fichier : il apparaît\ndans le menu et les nouveaux fichiers en sont des copies.",
        // formats
        "colShow": "Afficher",
        "colKey": "Raccourci",
        "colOpen": "Ouvrir avec…",
        "fmtLast": "Au moins un élément doit rester visible",
        "openFail": "App non modifiée : vous avez refusé dans la fenêtre macOS ou la modification a été refusée.",
        // creation
        "openAfter": "Ouvrir le fichier juste après sa création",
        "fromClip": "Depuis le presse-papiers…",
        "clipName": "Depuis le presse-papiers",
        "renameFinder": "Nommer directement dans le Finder",
        "templatesChange": "Modifier…",
        "tipTemplatesChange": "Choisir un autre dossier de modèles, par exemple dans iCloud Drive. Vos modèles y sont copiés.",
        "tipRename": "Crée le fichier tout de suite et lance le renommage dans le Finder. Nécessite l’autorisation Accessibilité.",
        "tipKey": "Cliquez puis appuyez sur Contrôle + Option + une touche. Le raccourci crée ce fichier directement, sans menu.",
        "tipOpen": "L’app avec laquelle macOS ouvre ce type de fichier.",
    ],
    "es": [
        "base": "Nuevo archivo",
        "createIn": "Crear en «%@»",
        "desktop": "Escritorio",
        "folder": "Nueva carpeta",
        "settings": "Ajustes…",
        "quit": "Salir",
        "text": "Texto",
        "askFolder": "Nombre de la nueva carpeta",
        "askFile": "Nombre del nuevo archivo",
        "askWhere": "Se creará en «%@»",
        "create": "Crear",
        "cancel": "Cancelar",
        "failTitle": "No se pudo crear «%@»",
        "failText": "Puede que no tengas permiso para escribir en esta carpeta.",
        "winTitle": "Blankly — Ajustes",
        "hotkey": "Atajo:",
        "press": "Pulsa un atajo…",
        "needMod": "Usa ⌘, ⌃ o ⌥",
        "busy": "Atajo en uso por otra app",
        "language": "Idioma:",
        "fmtKeys": "Formatos:",
        "fmtSetup": "Configurar…",
        "fmtTitle": "Blankly — Formatos",
        "fmtHint": "Arrastra las filas para definir el orden. Para un atajo, haz clic en un campo y pulsa\n⌃⌥ con una tecla: el archivo se crea al instante, solo falta escribir el nombre.",
        "fmtClear": "Quitar atajo",
        "needCtrlOpt": "Usa ⌃ y ⌥ juntas",
        "usedMenu": "Ya en uso: menú de Blankly",
        "usedFor": "Ya en uso: %@",
        "usedSystem": "En uso por macOS: Ajustes → Teclado",
        "login": "Abrir al iniciar sesión",
        "loginFail": "No se pudo cambiar el elemento de inicio",
        "myTemplates": "Mis plantillas",
        "updateAvail": "Versión %@ disponible — actualizar",
        "checkNow": "Buscar actualizaciones…",
        "finderRow": "Clic derecho en el Finder: %@",
        "on": "activado",
        "off": "desactivado",
        "finderBtn": "Activar…",
        "checkUpdates": "Buscar actualizaciones a diario",
        "templatesBtn": "Carpeta de plantillas…",
        "templatesHint": "Coloca ahí cualquier archivo: aparecerá en el menú\ny los archivos nuevos serán copias suyas.",
        // formats
        "colShow": "Mostrar",
        "colKey": "Atajo",
        "colOpen": "Abrir con…",
        "fmtLast": "Debe quedar visible al menos un elemento",
        "openFail": "App no cambiada: se rechazó en el aviso de macOS o no se permitió.",
        // creation
        "openAfter": "Abrir el archivo justo después de crearlo",
        "fromClip": "Desde el portapapeles…",
        "clipName": "Desde el portapapeles",
        "renameFinder": "No pedir nombre: renombrar en el Finder",
        "templatesChange": "Cambiar…",
        "tipTemplatesChange": "Elegir otra carpeta de plantillas, por ejemplo en iCloud Drive. Tus plantillas se copian allí.",
        "tipRename": "Crea el archivo al instante y empieza a renombrarlo en el Finder. Necesita el permiso de Accesibilidad.",
        "tipKey": "Haz clic y pulsa Control + Opción + una tecla. El atajo crea este archivo al instante, sin menú.",
        "tipOpen": "La app con la que macOS abre este tipo de archivo.",
    ],
    "zh-Hans": [
        "base": "新建文件",
        "createIn": "在“%@”中创建",
        "desktop": "桌面",
        "folder": "新建文件夹",
        "settings": "设置…",
        "quit": "退出",
        "text": "文本",
        "askFolder": "新文件夹的名称",
        "askFile": "新文件的名称",
        "askWhere": "将创建在“%@”中",
        "create": "创建",
        "cancel": "取消",
        "failTitle": "无法创建“%@”",
        "failText": "你可能没有此文件夹的写入权限。",
        "winTitle": "Blankly — 设置",
        "hotkey": "快捷键：",
        "press": "请按下快捷键…",
        "needMod": "请使用 ⌘、⌃ 或 ⌥",
        "busy": "快捷键已被其他 App 占用",
        "language": "语言：",
        "fmtKeys": "格式：",
        "fmtSetup": "自定…",
        "fmtTitle": "Blankly — 格式",
        "fmtHint": "拖动行以设置顺序。要设置快捷键，请点按输入框，\n再按下 ⌃⌥ 加一个键：文件会立即创建，只需输入名称。",
        "fmtClear": "移除快捷键",
        "needCtrlOpt": "请同时使用 ⌃ 和 ⌥",
        "usedMenu": "已被占用：Blankly 菜单",
        "usedFor": "已被占用：%@",
        "usedSystem": "已被 macOS 占用：设置 → 键盘",
        "login": "登录时打开",
        "loginFail": "无法更改登录项",
        "myTemplates": "我的模板",
        "updateAvail": "版本 %@ 可用 — 更新",
        "checkNow": "检查更新…",
        "finderRow": "访达右键菜单：%@",
        "on": "已开启",
        "off": "已关闭",
        "finderBtn": "开启…",
        "checkUpdates": "每天检查更新",
        "templatesBtn": "模板文件夹…",
        "templatesHint": "把任意文件放进去，它就会出现在菜单中，\n新建的文件就是它的副本。",
        // formats
        "colShow": "显示",
        "colKey": "快捷键",
        "colOpen": "打开方式…",
        "fmtLast": "至少要保留一个可见项目",
        "openFail": "未更改 App：你在 macOS 提示中拒绝了，或系统拒绝了更改。",
        // creation
        "openAfter": "创建后立即打开文件",
        "fromClip": "来自剪贴板…",
        "clipName": "来自剪贴板",
        "renameFinder": "不询问名称，直接在访达中重命名",
        "templatesChange": "更改…",
        "tipTemplatesChange": "选择其他模板文件夹，例如 iCloud 云盘中的文件夹。现有模板会复制到那里。",
        "tipRename": "立即创建文件，并在访达中开始重命名。需要“辅助功能”权限。",
        "tipKey": "点按后按下 Control + Option + 一个键。该快捷键会直接创建此文件，无需菜单。",
        "tipOpen": "macOS 用来打开此类文件的应用。",
    ],
    "ja": [
        "base": "新規ファイル",
        "createIn": "“%@”に作成",
        "desktop": "デスクトップ",
        "folder": "新規フォルダ",
        "settings": "設定…",
        "quit": "終了",
        "text": "テキスト",
        "askFolder": "新規フォルダの名前",
        "askFile": "新規ファイルの名前",
        "askWhere": "“%@”に作成されます",
        "create": "作成",
        "cancel": "キャンセル",
        "failTitle": "“%@”を作成できませんでした",
        "failText": "このフォルダに書き込む権限がない可能性があります。",
        "winTitle": "Blankly — 設定",
        "hotkey": "ショートカット:",
        "press": "ショートカットを押してください…",
        "needMod": "⌘、⌃、⌥ のいずれかを使用してください",
        "busy": "ショートカットは別のアプリで使用されています",
        "language": "言語:",
        "fmtKeys": "フォーマット:",
        "fmtSetup": "カスタマイズ…",
        "fmtTitle": "Blankly — フォーマット",
        "fmtHint": "行をドラッグして順序を変更します。ショートカットは、フィールドをクリックして\n⌃⌥ とキーを押して設定します。ファイルがすぐに作成され、名前を入力するだけです。",
        "fmtClear": "ショートカットを削除",
        "needCtrlOpt": "⌃ と ⌥ を同時に使用してください",
        "usedMenu": "使用済み: Blankly のメニュー",
        "usedFor": "使用済み: %@",
        "usedSystem": "macOS で使用中: 設定 → キーボード",
        "login": "ログイン時に開く",
        "loginFail": "ログイン項目を変更できませんでした",
        "myTemplates": "マイテンプレート",
        "updateAvail": "バージョン %@ が利用可能 — アップデート",
        "checkNow": "アップデートを確認…",
        "finderRow": "Finder の右クリック: %@",
        "on": "オン",
        "off": "オフ",
        "finderBtn": "オンにする…",
        "checkUpdates": "毎日アップデートを確認",
        "templatesBtn": "テンプレートフォルダ…",
        "templatesHint": "任意のファイルを入れると、メニューに表示され、\n新規ファイルはそのコピーになります。",
        // formats
        "colShow": "表示",
        "colKey": "ショートカット",
        "colOpen": "開くアプリ…",
        "fmtLast": "少なくとも 1 つの項目を表示したままにする必要があります",
        "openFail": "アプリは変更されませんでした。macOS の確認で拒否したか、変更が拒否されました。",
        // creation
        "openAfter": "作成後すぐにファイルを開く",
        "fromClip": "クリップボードから…",
        "clipName": "クリップボードから",
        "renameFinder": "名前を尋ねずに Finder で名前を変更",
        "templatesChange": "変更…",
        "tipTemplatesChange": "別のテンプレートフォルダを選びます（例：iCloud Drive 内）。今のテンプレートはそこにコピーされます。",
        "tipRename": "ファイルをすぐに作成し、Finder で名前の変更を始めます。「アクセシビリティ」の許可が必要です。",
        "tipKey": "クリックして Control + Option + キーを押します。このショートカットでメニューなしでファイルを作成します。",
        "tipOpen": "macOS がこの種類のファイルを開くアプリ。",
    ],
]

// Нет перевода — английский. Нет и английской строки — сам ключ (видно в интерфейсе, не падает).
func L(_ k: String, _ lang: String) -> String { translations[lang]?[k] ?? translations["en"]?[k] ?? k }

// MARK: - Форматы

// Ширина столбцов окна «Форматы» (main.swift); Tests/LayoutTests.swift проверяет, что самые длинные названия на всех языках влезают.
let fmtShowColumnWidth: CGFloat = 88
let fmtNameColumnWidth: CGFloat = 220
let fmtKeyColumnWidth: CGFloat = 154 // кнопка 124 + крестик 26
let fmtOpenColumnWidth: CGFloat = 230

struct Format { let ext: String; let title: String }
func formatGroups(lang: String) -> [[Format]] {
    FormatList.groups(text: L("text", lang)).map { $0.map { Format(ext: $0.ext, title: $0.title) } }
}

// Пункты меню в нужном порядке: папка ("") и форматы с номером группы (для разделителей).
// available — есть ли чем открыть; hidden/order — из настроек (FormatPrefs).
func menuFormats(lang: String, order: [String], hidden: [String], available: (String) -> Bool)
    -> (all: [(format: Format, group: Int)], shown: [(format: Format, group: Int)]) {
    var items: [(format: Format, group: Int)] = [(Format(ext: "", title: L("folder", lang)), 0)]
    for (i, g) in formatGroups(lang: lang).enumerated() { items += g.map { ($0, i + 1) } }
    items = items.filter { available($0.format.ext) }
    let r = FormatPrefs.apply(items.map { $0.format.ext }, order: order, hidden: hidden)
    func pick(_ exts: [String]) -> [(format: Format, group: Int)] { exts.compactMap { e in items.first { $0.format.ext == e } } }
    return (pick(r.ordered), pick(r.shown))
}

// Название формата для подсказок: "" — папка
func formatTitle(_ ext: String, lang: String) -> String {
    ext.isEmpty ? L("folder", lang) : formatGroups(lang: lang).joined().first(where: { $0.ext == ext })?.title ?? ext
}

// MARK: - Имена

// Свободное имя: «Имя.ext», «Имя 1.ext», … (ext пустой — для папки)
func freeURL(in dir: URL, base: String, ext: String) -> URL {
    let suffix = ext.isEmpty ? "" : ".\(ext)"
    var url = dir.appendingPathComponent(base + suffix)
    var n = 1
    while FileManager.default.fileExists(atPath: url.path) {
        url = dir.appendingPathComponent("\(base) \(n)\(suffix)")
        n += 1
    }
    return url
}

// MARK: - Шаблоны: переменные

// {date} → 2026-11-05, {time} → 14-30, {name} → введённое имя
func fillVars(_ s: String, name: String, now: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    let date = f.string(from: now)
    f.dateFormat = "HH-mm"
    let time = f.string(from: now)
    return s.replacingOccurrences(of: "{date}", with: date)
        .replacingOccurrences(of: "{time}", with: time)
        .replacingOccurrences(of: "{name}", with: name)
}

// Содержимое файла-шаблона: текст в utf-8 (без нулевых байтов) подставляем, остальное — как есть
func fillData(_ data: Data, name: String, now: Date = Date()) -> Data {
    guard !data.contains(0), let text = String(data: data, encoding: .utf8) else { return data }
    return Data(fillVars(text, name: name, now: now).utf8)
}

// Копия шаблона (файл или папка целиком) в dst; в папке подставляем и имена внутри
func copyTemplate(from src: URL, to dst: URL, name: String, now: Date = Date()) throws {
    let fm = FileManager.default
    // символическую ссылку копируем как ссылку: не заходим в неё (петля) и не пишем через неё в чужой файл
    if (try? src.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
        try fm.copyItem(at: src, to: dst)
        return
    }
    var isDir: ObjCBool = false
    fm.fileExists(atPath: src.path, isDirectory: &isDir)
    if isDir.boolValue {
        try fm.createDirectory(at: dst, withIntermediateDirectories: false)
        for item in try fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil) where item.lastPathComponent != ".DS_Store" {
            let child = fillVars(item.lastPathComponent, name: name, now: now).replacingOccurrences(of: "/", with: "-")
            try copyTemplate(from: item, to: dst.appendingPathComponent(child), name: name, now: now)
        }
    } else {
        try fm.copyItem(at: src, to: dst)
        let data = try Data(contentsOf: dst)
        let filled = fillData(data, name: name, now: now)
        if filled != data { try filled.write(to: dst) } // запись поверх сохраняет права файла
    }
}

// MARK: - Буфер обмена

// Расширение для текста из буфера: JSON-объект или массив → json, HTML-документ → html, иначе txt
func clipboardExt(text: String) -> String {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let head = t.prefix(15).lowercased()
    if head.hasPrefix("<!doctype") || head.hasPrefix("<html") { return "html" }
    if t.hasPrefix("{") || t.hasPrefix("["),
       (try? JSONSerialization.jsonObject(with: Data(t.utf8))) != nil { return "json" }
    return "txt"
}

// MARK: - Сочетания клавиш

func carbonMods(_ f: NSEvent.ModifierFlags) -> UInt32 {
    var m: UInt32 = 0
    if f.contains(.control) { m |= UInt32(controlKey) }
    if f.contains(.option) { m |= UInt32(optionKey) }
    if f.contains(.shift) { m |= UInt32(shiftKey) }
    if f.contains(.command) { m |= UInt32(cmdKey) }
    return m
}

// Включённое сочетание macOS из «Клавиатура → Сочетания клавиш» (скриншоты, Spotlight, язык ввода…).
// symbolic — словарь AppleSymbolicHotKeys; в тестах подставляем свой.
func systemShortcutTaken(code: UInt32, mods: UInt32, symbolic all: [String: Any]?) -> Bool {
    guard let all else { return false }
    for case let item as [String: Any] in all.values {
        guard (item["enabled"] as? Bool) == true,
              let p = (item["value"] as? [String: Any])?["parameters"] as? [Int], p.count == 3 else { continue }
        if UInt32(p[1]) == code && carbonMods(NSEvent.ModifierFlags(rawValue: UInt(p[2]))) == mods { return true }
    }
    return false
}

// Почему сочетание взять нельзя (nil — можно). owner — чьё сочетание меняем: "main" или расширение формата.
// Сочетания из меню других программ macOS узнать не даёт — поэтому для форматов требуем ⌃⌥.
func shortcutConflict(code: UInt32, mods: UInt32, owner: String, menu: (code: UInt32, mods: UInt32),
                      formatKeys: [String: [Int]], symbolic: [String: Any]?, lang: String) -> String? {
    if owner != "main" && code == menu.code && mods == menu.mods { return L("usedMenu", lang) }
    for (ext, k) in formatKeys where ext != owner && k == [Int(code), Int(mods)] {
        return String(format: L("usedFor", lang), formatTitle(ext, lang: lang))
    }
    if systemShortcutTaken(code: code, mods: mods, symbolic: symbolic) { return L("usedSystem", lang) }
    return nil
}
