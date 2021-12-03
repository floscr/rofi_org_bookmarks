#!/usr/bin/env bash

nix build .\#rofi_org_bookmarks_backup --print-build-logs
# ./result/bin/rofi_org_bookmarks_backup $@
