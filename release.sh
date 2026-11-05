#!/bin/zsh
# Выпуск новой версии: собрать, подписать архив ключом Sparkle, сделать appcast.xml и выложить релиз на GitHub.
#   zsh release.sh --notes "Что нового"     — релиз vВЕРСИЯ (версия задаётся в build.sh)
# Аргументы после имени скрипта уходят в `gh release create` как есть (--notes, --prerelease…).
# Ключ подписи лежит в Связке ключей (запись app.blankly); macOS может один раз спросить доступ к нему.
set -e
cd "${0:A:h}"
zsh build.sh --no-install

VERSION=$(defaults read "$PWD/build/Blankly.app/Contents/Info.plist" CFBundleShortVersionString)
TAG=${BLANKLY_TAG:-v$VERSION}
SPARKLE=.vendor/Sparkle-$(sed -n 's/^SPARKLE_VER=//p' build.sh)

# sparkle:edSignature="…" length="…"
SIGNATURE=$("$SPARKLE/bin/sign_update" --account app.blankly build/Blankly.zip)

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
      <enclosure url="https://github.com/Guf-Hub/blankly/releases/download/$TAG/Blankly.zip"
                 type="application/octet-stream" $SIGNATURE />
    </item>
  </channel>
</rss>
EOF

gh release create "$TAG" "build/Blankly-$VERSION.dmg" build/Blankly.zip build/appcast.xml --title "Blankly $VERSION" "$@"
shasum -a 256 "build/Blankly-$VERSION.dmg"
