#!/bin/zsh
# Выпуск новой версии: собрать, подписать архив ключом Sparkle, сделать appcast.xml и выложить релиз на GitHub.
#   zsh release.sh --notes "Что нового" [--notes-ru "Что нового по-русски"]
#   zsh release.sh --from-ci <run-id> --notes "…"   — взять подписанные и нотаризованные Blankly.zip и .dmg
#                                                     из прогона workflow «release-build», а не собирать локально
#                                                     (прогон в чужом форке: --ci-repo владелец/blankly)
# --notes / --notes-file — описание версии (Markdown): уходит и в релиз GitHub, и в окно обновления Sparkle.
# --notes-ru / --notes-ru-file — то же по-русски: в appcast это <description xml:lang="ru">, Sparkle выберет по языку системы.
# Остальные аргументы уходят в `gh release create` как есть (--prerelease…).
# Ключ Sparkle лежит в Связке ключей (запись app.blankly); macOS может один раз спросить доступ к нему.
set -e
cd "${0:A:h}"

NOTES=; NOTES_RU=; FROM_CI=; CI_REPO=; GH_ARGS=()
while (( $# )); do
  case "$1" in
    --notes)          NOTES=$2; GH_ARGS+=("$1" "$2"); shift 2 ;;
    --notes-file)     NOTES=$(<"$2"); GH_ARGS+=("$1" "$2"); shift 2 ;;
    --notes-ru)       NOTES_RU=$2; shift 2 ;;
    --notes-ru-file)  NOTES_RU=$(<"$2"); shift 2 ;;
    --from-ci)        FROM_CI=$2; shift 2 ;;
    --ci-repo)        CI_REPO=$2; shift 2 ;;
    *)                GH_ARGS+=("$1"); shift ;;
  esac
done

SPARKLE=.vendor/Sparkle-$(sed -n 's/^SPARKLE_VER=//p' build.sh)

if [[ -n "$FROM_CI" ]]; then
  zsh build.sh --sparkle-only          # только инструменты Sparkle (sign_update)
  rm -rf build && mkdir -p build
  gh run download "$FROM_CI" ${CI_REPO:+-R "$CI_REPO"} -n Blankly -D build
  [[ -f build/Blankly.zip ]] || { echo "В прогоне $FROM_CI нет Blankly.zip" >&2; exit 1 }
  # версию берём из самого приложения в архиве
  unzip -q -o build/Blankly.zip 'Blankly.app/Contents/Info.plist' -d build/obj-ci
  VERSION=$(defaults read "$PWD/build/obj-ci/Blankly.app/Contents/Info.plist" CFBundleShortVersionString)
  [[ -f "build/Blankly-$VERSION.dmg" ]] || { echo "В прогоне нет Blankly-$VERSION.dmg" >&2; exit 1 }
  rm -rf build/obj-ci
else
  zsh build.sh --no-install
  VERSION=$(defaults read "$PWD/build/Blankly.app/Contents/Info.plist" CFBundleShortVersionString)
fi
TAG=${BLANKLY_TAG:-v$VERSION}

# sparkle:edSignature="…" length="…"
SIGNATURE=$("$SPARKLE/bin/sign_update" --account app.blankly build/Blankly.zip)

# Описание версии. Sparkle 2.9+ показывает Markdown сам (sparkle:descriptionFormat="markdown").
# CDATA нельзя прервать, поэтому «]]>» внутри текста разрезаем.
cdata() { printf '%s' "<![CDATA[${1//]]>/]]]]><![CDATA[>}]]>" }
DESCRIPTION=
if [[ -n "$NOTES" ]]; then
  if [[ -n "$NOTES_RU" ]]; then
    DESCRIPTION+="      <description sparkle:descriptionFormat=\"markdown\" xml:lang=\"en\">$(cdata "$NOTES")</description>"$'\n'
    DESCRIPTION+="      <description sparkle:descriptionFormat=\"markdown\" xml:lang=\"ru\">$(cdata "$NOTES_RU")</description>"$'\n'
  else
    DESCRIPTION+="      <description sparkle:descriptionFormat=\"markdown\">$(cdata "$NOTES")</description>"$'\n'
  fi
fi

cat > build/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Blankly</title>
    <item>
      <title>$VERSION</title>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <link>https://github.com/Guf-Hub/blankly/releases/tag/$TAG</link>
${DESCRIPTION}      <enclosure url="https://github.com/Guf-Hub/blankly/releases/download/$TAG/Blankly.zip"
                 type="application/octet-stream" $SIGNATURE />
    </item>
  </channel>
</rss>
EOF
xmllint --noout build/appcast.xml

gh release create "$TAG" "build/Blankly-$VERSION.dmg" build/Blankly.zip build/appcast.xml --title "Blankly $VERSION" "${GH_ARGS[@]}"
shasum -a 256 "build/Blankly-$VERSION.dmg"
