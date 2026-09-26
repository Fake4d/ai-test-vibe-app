#!/bin/bash
# Aktualisiert Codex CLI aus dem offiziellen GitHub-Release (openai/codex).
# Prüft Release-Tag, SHA-256 des Pakets (laut GitHub-API) und die Version im Paket,
# bevor etwas ausgetauscht wird; scheitert etwas danach, wird zurückgebaut.
set -euo pipefail

basis="$HOME/.local/share"
ziel="$basis/codex"
link="$HOME/.local/bin/codex"
tmp=""
rollback=0
hat_alt=0
hat_link=0

cleanup() {
    status=$?
    trap - EXIT
    if (( rollback )); then
        echo "Update fehlgeschlagen – stelle vorherigen Zustand wieder her." >&2
        rm -rf -- "$ziel"
        if (( hat_alt )); then
            mv -- "$tmp/vorher" "$ziel" || status=1
        fi
        rm -f -- "$link"
        if (( hat_link )); then
            cp -a -- "$tmp/link-vorher" "$link" || status=1
        fi
    fi
    if [[ -n "$tmp" ]]; then
        # Bei fehlgeschlagener Wiederherstellung die Sicherung erhalten.
        if [[ -e "$tmp/vorher" ]]; then
            echo "Sicherung erhalten unter: $tmp" >&2
        else
            rm -rf -- "$tmp"
        fi
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p -- "$basis" "${link%/*}"
exec 9>"$basis/codex-update.lock"
flock -n 9 || { echo "Ein Codex-Update läuft bereits." >&2; exit 1; }
[[ ! -d "$link" ]] || { echo "Linkpfad ist ein Verzeichnis: $link" >&2; exit 1; }

paket="codex-package-x86_64-unknown-linux-musl.tar.gz"
alt=$("$link" --version 2>/dev/null || echo "keine")
release=$(curl -fsSL --connect-timeout 15 --max-time 60 \
    https://api.github.com/repos/openai/codex/releases/latest 2>&1) || {
    echo "GitHub nicht erreichbar – nichts geändert. (${release##*$'\n'})" >&2; exit 1;
}
# Tag und SHA-256 des Pakets aus derselben Antwort. Fehlt eines, wird nichts installiert.
read -r tag sha < <(printf '%s' "$release" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    print("- -"); sys.exit()
paket = sys.argv[1]
digest = next((a.get("digest") or "" for a in d.get("assets", []) if a.get("name") == paket), "")
print(d.get("tag_name") or "-", digest.removeprefix("sha256:") or "-")
' "$paket")
[[ "$tag" != "-" ]] || { echo "Antwort von GitHub unverständlich – nichts geändert." >&2; exit 1; }
[[ "$sha" =~ ^[0-9a-f]{64}$ ]] || { echo "Keine SHA-256-Prüfsumme für $paket – nichts geändert." >&2; exit 1; }
[[ "$tag" =~ ^rust-v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || {
    echo "Unerwarteter Release-Tag: $tag" >&2; exit 1;
}
version="${BASH_REMATCH[1]}"
echo "Installiert: $alt – neueste: $version"
if [[ "$alt" == "codex-cli $version" ]]; then
    echo "Codex ist bereits aktuell."
    exit 0
fi

# Gleiches Dateisystem für den anschließenden Verzeichnistausch.
tmp=$(mktemp -d "$basis/.codex-update.XXXXXXXX")
url="https://github.com/openai/codex/releases/download/$tag/$paket"
curl -fsSL --connect-timeout 15 --max-time 600 "$url" -o "$tmp/codex.tar.gz" || {
    echo "Download fehlgeschlagen – nichts geändert." >&2; exit 1;
}
ist=$(sha256sum "$tmp/codex.tar.gz" | cut -d' ' -f1)
[[ "$ist" == "$sha" ]] || {
    echo "Prüfsumme stimmt nicht – nichts geändert." >&2
    echo "  erwartet: $sha" >&2
    echo "  erhalten: $ist" >&2
    exit 1
}
echo "Prüfsumme stimmt (SHA-256 laut GitHub)."
mkdir -- "$tmp/neu"
tar xzf "$tmp/codex.tar.gz" -C "$tmp/neu"
neu=$("$tmp/neu/bin/codex" --version)
[[ "$neu" == "codex-cli $version" ]] || {
    echo "Paketversion passt nicht zum Release: $neu" >&2; exit 1;
}

if [[ -e "$link" || -L "$link" ]]; then
    cp -a -- "$link" "$tmp/link-vorher"
    hat_link=1
fi
if [[ -e "$ziel" || -L "$ziel" ]]; then
    mv -- "$ziel" "$tmp/vorher"
    hat_alt=1
fi
rollback=1
mv -- "$tmp/neu" "$ziel"
ln -sfn -- "$ziel/bin/codex" "$link"
jetzt=$("$link" --version)
[[ "$jetzt" == "codex-cli $version" ]]
rollback=0

# Erst nach erfolgreicher Prüfung die bisherige Vorversion ersetzen.
if (( hat_alt )); then
    rm -rf -- "$ziel.alt"
    mv -- "$tmp/vorher" "$ziel.alt"
fi
echo "Jetzt: $jetzt"
if (( hat_alt )); then
    echo "Vorversion liegt in $ziel.alt"
fi
