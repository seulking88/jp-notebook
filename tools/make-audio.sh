#!/bin/zsh
# index.html에 있는 모든 표현·예문의 일본어 녹음(a/<해시>.mp3)을 만든다.
# 이미 있는 파일은 건너뛰고, 더 이상 쓰지 않는 파일은 지운다.
# 필요: macOS say(Kyoko 음성), ffmpeg, node
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p a
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

node tools/list-texts.js index.html \
  | node -e 'for (const x of JSON.parse(require("fs").readFileSync(0, "utf8"))) console.log(x.h + "\t" + x.text)' \
  > "$tmp/texts.tsv"

gen() {
  local line="$1" h t
  h="${line%%$'\t'*}"; t="${line#*$'\t'}"
  [[ -s "a/$h.mp3" ]] && return 0
  say -v Kyoko -r 165 -o "$tmp/$h.aiff" -- "$t"
  ffmpeg -loglevel error -y -i "$tmp/$h.aiff" -ac 1 -ar 22050 -b:a 48k "a/$h.mp3"
  echo "made a/$h.mp3  $t"
}

# 여러 개를 동시에 녹음
while IFS= read -r line; do
  gen "$line" &
  while (( $(jobs -r | wc -l) >= 10 )); do sleep 0.2; done
done < "$tmp/texts.tsv"
wait

cut -f1 "$tmp/texts.tsv" | sed 's/$/.mp3/' | sort > "$tmp/want"
ls a | sort > "$tmp/have"
comm -13 "$tmp/want" "$tmp/have" | while read -r f; do rm -f "a/$f"; echo "removed a/$f"; done
missing=$(comm -23 "$tmp/want" <(ls a | sort) | wc -l | tr -d ' ')
echo "audio files: $(ls a | wc -l | tr -d ' '), missing: $missing"
[[ "$missing" == 0 ]]
