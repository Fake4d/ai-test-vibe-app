# codex-update

Installiert bzw. aktualisiert die [Codex CLI](https://github.com/openai/codex) von OpenAI
aus dem offiziellen GitHub-Release – ohne Node/npm, als fertiges Linux-Paket (x86_64, musl).

## Was das Skript prüft, bevor es etwas austauscht

- **Release-Tag** hat die erwartete Form (`rust-vX.Y.Z`).
- **SHA-256** des heruntergeladenen Pakets stimmt mit der Prüfsumme überein, die die
  GitHub-API zu diesem Release veröffentlicht. Fehlt sie oder weicht sie ab: Abbruch.
- **Version im Paket** passt zum Release.

Erst dann wird die neue Version eingesetzt. Scheitert danach etwas, wird automatisch auf den
vorherigen Stand zurückgebaut. Eine Sperre verhindert zwei gleichzeitige Läufe; ist bereits
die neueste Version installiert, passiert nichts.

## Installation

```bash
curl -fsSLO https://raw.githubusercontent.com/Fake4d/ai-test-vibe-app/main/tools/codex-update/codex-update.sh
chmod +x codex-update.sh
mkdir -p ~/.local/bin && mv codex-update.sh ~/.local/bin/codex-update
codex-update          # installiert beim ersten Mal, aktualisiert danach
codex login --device-auth   # einmalig anmelden (ChatGPT-Konto)
```

## Wo was liegt

| Pfad | Inhalt |
|---|---|
| `~/.local/share/codex/` | aktuelle Version |
| `~/.local/share/codex.alt/` | vorherige Version (Rückfallebene) |
| `~/.local/bin/codex` | Link auf die aktuelle Version |

## Getestet

Auf Ubuntu 26.04 in einem abgeschotteten Test-Home: Erstinstallation, Update mit Vorversion,
„bereits aktuell“, kein Netz, Abbruch im Download, falsche Prüfsumme (erzwungen) und ein
erzwungener Fehler nach dem Austausch mit Rückbau – jeweils mit dem erwarteten Ergebnis.

Braucht: `bash`, `curl`, `python3`, `tar`, `sha256sum`, `flock`.
