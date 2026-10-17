<p align="center"><img src="assets/icon.png" width="160" alt="claude-clone"></p>

# claude-clone

Makes a second, isolated copy of Claude Desktop on macOS, so you can stay signed in to two accounts at once (for example work and personal).

The clone is a separate app (`/Applications/<Name>.app`) with its own bundle ID and its own data folder (`~/Library/Application Support/<slug>`). A colored label badge on its icon tells the two apart. The original Claude.app is never modified.

## Requirements

- macOS
- Claude Desktop installed in `/Applications`
- An admin user (write access to `/Applications`)

## Install

```sh
brew tap haric655/claude-clone
brew install claude-clone
```

The tap repo is private, so git must be able to authenticate to GitHub. Run `gh auth setup-git` once, or tap with an SSH URL instead:

```sh
brew tap haric655/claude-clone git@github.com:haric655/homebrew-claude-clone.git
```

Latest `main` instead of the tagged release:

```sh
brew install --HEAD claude-clone
```

## Usage

Interactive:

```
$ claude-clone
[1/3] App name [Claude Personal]:
[2/3] Icon label [Personal] (- keeps the original icon):
[3/3] Badge color (hex) [#1F2937]:
```

A summary is shown, then `[y/N]` asks for confirmation.

Non-interactive:

```sh
claude-clone --name "Claude Work" --label "Work" --color "#2E7D32" --yes
```

Use `--label -` to keep the original icon.

| Flag | Meaning | Default |
| --- | --- | --- |
| `--name NAME` | App name | `Claude Personal` |
| `--label LABEL` | Icon label (`-` keeps the original icon) | name without "Claude" |
| `--color HEX` | Badge color | `#1F2937` |
| `--source PATH` | App to copy | `/Applications/Claude.app` |
| `--yes` | Skip the confirmation | |
| `--version` | Print the version | |
| `--help` | Show help | |

The slug is the name with spaces turned into hyphens and anything outside `[A-Za-z0-9-]` removed (`Claude Test` becomes `Claude-Test`).

Running it again with the same name replaces the existing clone (only if it is a clone) and keeps the account data.

## After each Claude update

The clone is a copy of the old version. Re-run the same command to refresh it. Account data in `~/Library/Application Support/<slug>` is kept.

## First sign-in

Quit the original Claude before signing in to the clone. Sign-in completes through a `claude://` deep link, which goes to whichever Claude app is running or registered.

## Uninstall

```sh
rm -rf "/Applications/<Name>.app"
```

Optionally delete `~/Library/Application Support/<slug>` by hand. This deletes that account's local data.

## Troubleshooting

**Signing errors, "app is damaged", "unable to find helper app".** Re-run claude-clone: it re-signs inside-out, without `--deep`. Do not edit `CFBundleName` in the clone: Electron finds its helper apps by that name. Check the result:

```sh
codesign --verify --deep --strict "/Applications/<Name>.app"
```

Never re-sign manually with `codesign --deep`.

**Icon did not update.** Restart the Dock and re-register the app:

```sh
killall Dock
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/<Name>.app"
```

Or `touch "/Applications/<Name>.app"`.

**Sign-in landed in the wrong window.** Quit all Claude apps, open only the clone, and sign in again.

## Disclaimer

This is an unofficial modification. It is not affiliated with or supported by Anthropic. The copy is ad-hoc signed. Use at your own risk.

Claude's auto-update inside the clone may not work. Update the original, then re-run claude-clone.

## License

MIT
