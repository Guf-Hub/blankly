#!/bin/zsh
# Сборка Blankly: универсальное приложение (Apple Silicon + Intel), иконка, архив для команды.
#   zsh build.sh            — собрать и установить в /Applications
#   zsh build.sh --no-install — только собрать (build/Blankly.app и build/Blankly.zip)
set -e
cd "${0:A:h}"
NAME=Blankly
VERSION=1.1
APP="/Applications/$NAME.app"
OUT="build/$NAME.app"

rm -rf build && mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources/templates" build/obj

# 1. Код: две архитектуры → один файл
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos13" -o "build/obj/$NAME-$arch" main.swift
done
lipo -create build/obj/$NAME-arm64 build/obj/$NAME-x86_64 -output "$OUT/Contents/MacOS/$NAME"

# 1б. Расширение Finder (пункт «Новый файл…» в правом клике)
EXT="$OUT/Contents/PlugIns/BlanklyFinder.appex"
mkdir -p "$EXT/Contents/MacOS"
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos13" -application-extension -module-name BlanklyFinder \
    -Xlinker -e -Xlinker _NSExtensionMain -o "build/obj/ext-$arch" FinderExtension.swift
done
lipo -create build/obj/ext-arm64 build/obj/ext-x86_64 -output "$EXT/Contents/MacOS/BlanklyFinder"
cat > "$EXT/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>$NAME</string>
	<key>CFBundleDisplayName</key><string>$NAME</string>
	<key>CFBundleIdentifier</key><string>app.blankly.finder</string>
	<key>CFBundleExecutable</key><string>BlanklyFinder</string>
	<key>CFBundlePackageType</key><string>XPC!</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>$VERSION</string>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key><dict/>
		<key>NSExtensionPointIdentifier</key><string>com.apple.FinderSync</string>
		<key>NSExtensionPrincipalClass</key><string>FinderSync</string>
	</dict>
</dict>
</plist>
EOF
printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
  '<plist version="1.0"><dict><key>com.apple.security.app-sandbox</key><true/></dict></plist>' > build/obj/ext.entitlements

# 2. Иконка: рисуем 1024 и режем на все размеры
ICONSET=build/obj/AppIcon.iconset; mkdir -p "$ICONSET"
swift icon.swift a build/obj/icon-1024.png >/dev/null
for s in 16 32 128 256 512; do
  sips -z $s $s build/obj/icon-1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) build/obj/icon-1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$OUT/Contents/Resources/AppIcon.icns"

# 3. Шаблоны офисных файлов и Info.plist
cp Resources/templates/empty.* "$OUT/Contents/Resources/templates/"
cat > "$OUT/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>$NAME</string>
	<key>CFBundleDisplayName</key><string>$NAME</string>
	<key>CFBundleIdentifier</key><string>app.blankly</string>
	<key>CFBundleExecutable</key><string>$NAME</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>$VERSION</string>
	<key>LSUIElement</key><true/>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>CFBundleURLTypes</key>
	<array><dict>
		<key>CFBundleURLName</key><string>app.blankly</string>
		<key>CFBundleURLSchemes</key><array><string>blankly</string></array>
	</dict></array>
	<key>NSAppleEventsUsageDescription</key><string>Чтобы узнать, какая папка открыта в Finder, и создать файл в ней.</string>
</dict>
</plist>
EOF
# подпись: сначала расширение (с песочницей), потом приложение
codesign --force --sign - --entitlements build/obj/ext.entitlements "$EXT"
codesign --force --sign - "$OUT"

# 4. Для раздачи: zip и DMG (окно «перетащите в Программы»)
ditto -c -k --keepParent "$OUT" "build/$NAME.zip"
DMGSRC=build/obj/dmg; mkdir -p "$DMGSRC"
cp -R "$OUT" "$DMGSRC/" && ln -s /Applications "$DMGSRC/Applications"
hdiutil create -quiet -volname "$NAME" -srcfolder "$DMGSRC" -ov -format UDZO "build/$NAME-$VERSION.dmg"
echo "built: $OUT, build/$NAME.zip, build/$NAME-$VERSION.dmg"

[[ "$1" == "--no-install" ]] && exit 0

# 5. Установка: остановить запущенную копию и заменить
osascript -e "if application id \"app.blankly\" is running then tell application id \"app.blankly\" to quit" >/dev/null 2>&1 || true
rm -rf "$APP"
cp -R "$OUT" "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "installed: $APP"
# 6. Запустить заново в фоне, чтобы сочетание клавиш сразу работало
open -a "$APP" --args --background
