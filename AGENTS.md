# AGENTS.md

## Development environment

The development environment is configured in `.devcontainer/`. Manage it from the repository root on the host using the Makefile targets or directly through the `devcontainer`, `docker` and `docker compose` CLIs.

- `devcontainer`: `ubuntu` 26.04.
- `wiremock`: `wiremock/wiremock` 3.13.2.

```sh
# start the development environment
make up

# run a workspace command
devcontainer exec --workspace-folder . COMMAND ARG...

# run a shell command
devcontainer exec --workspace-folder . bash -c 'COMMAND ARG... | COMMAND ARG...'

# run a sidecar command
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE COMMAND ARG...
```

## EditorConfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
max_line_length = 200
trim_trailing_whitespace = true

[*.go]
indent_size = tab
indent_style = tab
tab_width = 8

[*.ini]
max_line_length = off

[*.md]
indent_size = unset
indent_style = unset
max_line_length = off

[*.txt]
indent_size = unset
indent_style = unset
max_line_length = off

[LICENSE]
indent_size = unset
indent_style = unset
max_line_length = off

[Makefile]
indent_style = tab
max_line_length = off
```

## Repository layout

```text
.
|-- .devcontainer/
|   |-- .dockerignore
|   |-- Dockerfile
|   |-- devcontainer.json
|   |-- docker-compose.yml
|   `-- ...
|-- .editorconfig
|-- .gitattributes
|-- .gitignore
|-- .npmrc
|-- .prettierignore
|-- AGENTS.md
|-- AUTHORS.md
|-- LICENSE
|-- Makefile
|-- cmd/
|   `-- ...
|-- go.mod
|-- go.sum
|-- internal/
|   `-- ...
|-- package-lock.json
|-- package.json
`-- prettier.config.js
```

## Makefile targets

- `never`: Require an explicit target.
- `fix`: `go_fix` + `goimports_fix` + `gofmt_fix` + `go_mod_fix` + `prettier_fix` + `trimmer_fix`
- `check`: `devcontainer_gate` + `doctor` + `lint` + `analyze` + `test` + `coverage` + `audit`
- `doctor`: `git_check` + `npm_config_check` + `npm_doctor` + `npm_check` + `toolchain_check`
- `lint`: `gofmt_check` + `goimports_check` + `prettier_check` + `trimmer_check`
- `analyze`: `npm_check` + `go_mod_check` + `go_list_check` + `go_fix_check` + `go_vet_check` + `shadow_check`
- `test`: `devcontainer_gate` + `./go.mod` + `./go.sum` — Run automated tests.
- `fuzz`: `devcontainer_gate` + `./go.mod` + `./go.sum` — Run fuzz tests.
- `bench`: `devcontainer_gate` + `./go.mod` + `./go.sum` — Run benchmarks.
- `coverage`: `devcontainer_gate` + `./go.mod` + `./go.sum` — Measure and report test coverage.
- `audit`: `npm_audit` + `go_audit`
- `update`: `npm_config_check` + `npm_update` + `go_update`
- `clean`: Remove generated project files.
- `distclean`: `clean` + `deps_clean`
- `all`: `build_linux_amd64_v1` + `build_linux_amd64_v2` + `build_linux_amd64_v3` + `build_linux_arm64_v8` + `build_linux_arm64_v9` + `build_darwin_amd64_v1` + `build_darwin_amd64_v2` + `build_darwin_amd64_v3` + `build_darwin_arm64_v8` + `build_darwin_arm64_v9` + `native`
- `installdirs`: Create installation directories.
- `install`: `native` + `installdirs` — Install the application.
- `uninstall`: Uninstall the application.
- `installcheck`: Check the application installation.
- `dist`: `all` + `dist_linux_amd64_v1` + `dist_linux_amd64_v2` + `dist_linux_amd64_v3` + `dist_linux_arm64_v8` + `dist_linux_arm64_v9` + `dist_darwin_amd64_v1` + `dist_darwin_amd64_v2` + `dist_darwin_amd64_v3` + `dist_darwin_arm64_v8` + `dist_darwin_arm64_v9` — Create distribution packages and checksums.
- `postcreate`: `deps_install` + `toolchain_check`
- `up`: `host_gate` + `devcontainer_check` — Start the development environment.
- `shell`: `interactive_gate` + `host_gate` + `up` — Open a shell in the development environment.
- `stop`: `host_gate` — Stop the development environment.
- `down`: `host_gate` — Remove the development environment.
- `rebuild`: `host_gate` + `devcontainer_check` + `down` — Rebuild the development environment.
- `nuke`: `distclean` + `prune`
- `prune`: `host_gate` — Remove project container resources.
- `host_gate`: Require execution on the host.
- `devcontainer_gate`: Require execution in a Docker container.
- `interactive_gate`: Require an interactive terminal.
- `deps_install`: `npm_install` + `go_mod_download`
- `deps_clean`: `npm_clean`
- `trimmer_fix`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Fix whitespace formatting.
- `trimmer_check`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Check whitespace formatting.
- `prettier_fix`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./prettier.config.js` — Format files with Prettier.
- `prettier_check`: `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` + `./prettier.config.js` — Check formatting with Prettier.
- `npm_config_check`: `./.npmrc` — Check npm configuration.
- `npm_doctor`: Check the npm environment.
- `npm_check`: `npm_config_check` + `./node_modules/.package-lock.json` — Check npm dependencies.
- `npm_audit`: `npm_config_check` + `./node_modules/.package-lock.json` + `./package.json` + `./package-lock.json` — Audit npm dependency security.
- `npm_install`: `npm_config_check` + `./package.json` + `./package-lock.json` — Install npm dependencies.
- `npm_update`: `npm_config_check` + `./package.json` + `./package-lock.json` + `npm_clean` — Update npm dependencies.
- `npm_clean`: Remove installed npm dependencies.
- `go_mod_download`: `./go.mod` + `./go.sum` — Download and verify Go dependencies.
- `go_update`: `./go.mod` + `./go.sum` — Update Go dependencies and tools.
- `go_fix`: `./go.mod` + `./go.sum` — Apply Go code fixes.
- `go_mod_fix`: `./go.mod` + `./go.sum` — Update Go module metadata.
- `gofmt_fix`: `./go.mod` + `./go.sum` — Format Go code.
- `goimports_fix`: `./go.mod` + `./go.sum` — Format Go imports.
- `toolchain_check`: `./go.mod` — Print toolchain versions.
- `go_mod_check`: Check Go module metadata.
- `gofmt_check`: Check Go code formatting.
- `goimports_check`: Check Go import formatting.
- `go_list_check`: Check Go package dependencies.
- `go_fix_check`: Check for Go code fixes.
- `go_vet_check`: Analyze Go code with go vet.
- `shadow_check`: `./go.mod` + `./go.sum` — Check Go variable shadowing.
- `go_audit`: `./go.mod` + `./go.sum` — Verify Go dependencies and audit vulnerability findings.
- `build_linux_amd64_v1`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_linux_amd64_v2`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_linux_amd64_v3`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_linux_arm64_v8`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_linux_arm64_v9`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_darwin_amd64_v1`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_darwin_amd64_v2`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_darwin_amd64_v3`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_darwin_arm64_v8`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `build_darwin_arm64_v9`: `./go.mod` + `./go.sum` — Build the application for the selected platform.
- `native`: `./go.mod` + `./go.sum` — Build the application for the current CPU.
- `dist_linux_amd64_v1`: `build_linux_amd64_v1` — Package the application for x86-64-v1.
- `dist_linux_amd64_v2`: `build_linux_amd64_v2` — Package the application for x86-64-v2.
- `dist_linux_amd64_v3`: `build_linux_amd64_v3` — Package the application for x86-64-v3.
- `dist_linux_arm64_v8`: `build_linux_arm64_v8` — Package the application for the selected platform.
- `dist_linux_arm64_v9`: `build_linux_arm64_v9` — Package the application for the selected platform.
- `dist_darwin_amd64_v1`: `build_darwin_amd64_v1` — Package the application for the selected platform.
- `dist_darwin_amd64_v2`: `build_darwin_amd64_v2` — Package the application for the selected platform.
- `dist_darwin_amd64_v3`: `build_darwin_amd64_v3` — Package the application for the selected platform.
- `dist_darwin_arm64_v8`: `build_darwin_arm64_v8` — Package the application for the selected platform.
- `dist_darwin_arm64_v9`: `build_darwin_arm64_v9` — Package the application for the selected platform.
- `git_check`: Check repository integrity.
- `devcontainer_check`: `host_gate` — Check development environment configuration.
- `./node_modules/.package-lock.json`: `./.npmrc` + `./package.json` + `./package-lock.json` — Prepare npm dependencies.
