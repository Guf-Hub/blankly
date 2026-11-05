#!/bin/zsh
# Подпись и нотаризация Blankly. Вызывается из build.sh и из workflow release-build.
#   zsh sign.sh sign <Blankly.app> <ext.entitlements>   — подписать (изнутри наружу)
#   zsh sign.sh notarize <Blankly.app> <версия>         — нотаризовать, staple, пересобрать zip и DMG
#
# Без SIGN_IDENTITY подпись ad-hoc (как раньше), а нотаризация пропускается.
# Переменные окружения (значения никогда не печатаем):
#   SIGN_IDENTITY     — имя сертификата «Developer ID Application: … (TEAMID)»; пусто или «-» = ad-hoc
#   NOTARY_KEY_PATH   — путь к файлу ключа App Store Connect API (.p8)
#   NOTARY_KEY_ID, NOTARY_ISSUER_ID — идентификаторы этого ключа
set -e
set +x
MODE=$1; APP=$2
IDENTITY=${SIGN_IDENTITY:--}
NAME=${APP:t:r}

case "$MODE" in
sign)
  EXT="$APP/Contents/PlugIns/BlanklyFinder.appex"
  EXT_ENT=$3
  if [[ "$IDENTITY" == "-" ]]; then
    # ad-hoc: расширение (с песочницей), потом приложение
    codesign --force --sign - --entitlements "$EXT_ENT" "$EXT"
    codesign --force --sign - "$APP"
    exit 0
  fi
  # Developer ID + hardened runtime. Порядок: вложенное раньше внешнего.
  SIGN=(codesign --force --sign "$IDENTITY" --options runtime --timestamp)
  FW="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  "${SIGN[@]}" "$FW/XPCServices/Installer.xpc"
  "${SIGN[@]}" --preserve-metadata=entitlements "$FW/XPCServices/Downloader.xpc"
  "${SIGN[@]}" "$FW/Autoupdate"
  "${SIGN[@]}" "$FW/Updater.app"
  "${SIGN[@]}" "$APP/Contents/Frameworks/Sparkle.framework"
  # расширение Finder — со своими entitlements песочницы
  "${SIGN[@]}" --entitlements "$EXT_ENT" "$EXT"
  # приложению нужно управлять Finder через AppleScript
  APP_ENT=$(mktemp -t blankly-app-ent).plist
  cat > "$APP_ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.automation.apple-events</key><true/></dict></plist>
EOF
  "${SIGN[@]}" --entitlements "$APP_ENT" "$APP"
  rm -f "$APP_ENT"
  codesign --verify --deep --strict "$APP"
  echo "signed: $APP"
  ;;

notarize)
  VERSION=$3
  if [[ "$IDENTITY" == "-" ]]; then echo "ad-hoc: нотаризация пропущена"; exit 0; fi
  : "${NOTARY_KEY_PATH:?нет NOTARY_KEY_PATH}" "${NOTARY_KEY_ID:?нет NOTARY_KEY_ID}" "${NOTARY_ISSUER_ID:?нет NOTARY_ISSUER_ID}"
  NOTARIZE=(xcrun notarytool submit --wait --key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
  OUTDIR=${APP:h}
  # 1. приложение: отправить, дождаться, прикрепить квитанцию (staple)
  ditto -c -k --keepParent "$APP" "$OUTDIR/notarize-app.zip"
  "${NOTARIZE[@]}" "$OUTDIR/notarize-app.zip"
  rm -f "$OUTDIR/notarize-app.zip"
  xcrun stapler staple "$APP"
  # 2. zip и DMG собираем заново — уже со staple (тот же порядок, что в build.sh, шаг 4)
  ditto -c -k --keepParent "$APP" "$OUTDIR/$NAME.zip"
  DMGSRC=$OUTDIR/obj/dmg-notarized; rm -rf "$DMGSRC"; mkdir -p "$DMGSRC"
  cp -R "$APP" "$DMGSRC/" && ln -s /Applications "$DMGSRC/Applications"
  DMG="$OUTDIR/$NAME-$VERSION.dmg"; rm -f "$DMG"
  hdiutil create -quiet -volname "$NAME" -srcfolder "$DMGSRC" -ov -format UDZO "$DMG"
  codesign --force --sign "$IDENTITY" --timestamp "$DMG"
  # 3. DMG тоже нотаризуем и прикрепляем
  "${NOTARIZE[@]}" "$DMG"
  xcrun stapler staple "$DMG"
  spctl --assess --type execute --verbose "$APP"
  echo "notarized: $APP, $OUTDIR/$NAME.zip, $DMG"
  ;;

*) echo "usage: sign.sh sign <app> <ext.entitlements> | notarize <app> <version>" >&2; exit 2 ;;
esac
