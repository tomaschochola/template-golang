# template-golang

Go project template: versioned module layout with command and internal packages.

## Stack

- Language: Go 1.27
- Runtime: GNU/Linux
- Libraries: Go extended libraries
- Package managers: go modules, npm (JS tooling side)

## Toolchain

- Format: gofmt, goimports, prettier, trimmer
- Lint: go vet, shadow analyzer
- Test: go test with coverage gate, fuzz targets
- Audit: govulncheck, npm audit

## Devcontainer

- Base: official Go
- User: devcontainer
- Sidecars: none
- Up: `make up`
- Execute: `devcontainer exec --workspace-folder . <command>`
- Down: `make down`

## Makefile

- `update` — refresh locks, only tool that may touch them
- `fix` — auto-fix, may dirty tree
- `check` — full gate: doctor + lint + analyze + test + coverage + fuzz + dist + audit
- `doctor` — tree and toolchain ok
- `lint` — gofmt + goimports + prettier + trimmer checks
- `analyze` — go vet + shadow + module checks
- `test` — go test suite
- `coverage` — coverage gate
- `fuzz` — fuzz targets
- `benchmark` — benchmarks
- `profile` — profiles
- `dist` — release artifacts
- `audit` — govulncheck + npm audit
- `install` — install to prefix (`installdirs`, `uninstall`, `installcheck`)
- `postcreate` — first-time setup, runs automatically on create
- `stop` — stop container, keep it
- `down` — stop and remove container
- `clean` — drop generated files
- `distclean` — drop everything rebuildable
- `rebuild` — full rebuild, only when broken

## Layout

├── Makefile
├── .editorconfig
├── .devcontainer/
├── go.mod
├── package.json
├── prettier.config.js
├── LICENSE
├── AUTHORS.md
├── cmd/
│   └── template-golang/main.go
└── internal/
    └── app/
