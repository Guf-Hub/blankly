#!/bin/zsh
# Тесты логики Blankly без Xcode: Core.swift + Tests/*.swift → один исполняемый файл.
#   zsh test.sh
set -e
cd "${0:A:h}"
mkdir -p build/test
swiftc -o build/test/blankly-tests Core.swift FormatOrder.swift Languages.swift FinderExtension.swift Tests/*.swift
build/test/blankly-tests Resources/templates
