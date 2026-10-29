#!/usr/bin/env bash
# Builds from clean, edits only the body of greeting() in Greeting.kt, then builds three more times:
# incrementally, again without any change, and with --rerun-tasks. Greeting.kt is restored on exit.
set -u
cd "$(dirname "$0")"
FILE=src/commonMain/kotlin/Greeting.kt
LOG=$(mktemp)
cp "$FILE" "$FILE.orig"
trap 'mv "$FILE.orig" "$FILE"; rm -f "$LOG"' EXIT

build() {
    echo "== $1"
    shift
    if ./gradlew --quiet "$@" compileKotlinJvm >"$LOG" 2>&1; then
        echo "BUILD SUCCESSFUL"
    else
        grep '^e: ' "$LOG" || cat "$LOG"
        echo "BUILD FAILED"
    fi
}

rm -rf build .kotlin
build "clean build"
sed -i.bak 's/Holder.name$/Holder.name + "!"/' "$FILE" && rm "$FILE.bak"
build "after a body-only edit of greeting()"
build "again, without any change"
build "with --rerun-tasks" --rerun-tasks
