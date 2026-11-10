# AGENTS.md

Edit AGENTS.md and README.md only when explicitly requested.

Freely manage PLAN.md, NOTES.md, and ARCHITECTURE.md for your own work. Keep them gitignored and never commit them.

## Language

- Go 1.27
- Go standard library 1.27

## Platform

- Operating system: GNU/Linux, Linux kernel 7.0
- Architecture: x86-64
- ISA: x86-64-v1, x86-64-v2, x86-64-v3
- Endianness: little-endian

- Operating system: GNU/Linux, Linux kernel 7.0
- Architecture: AArch64
- ISA: ARMv8.0-A, ARMv9.0-A
- Endianness: little-endian

- Operating system: macOS 26.0
- Architecture: x86-64
- ISA: x86-64-v1, x86-64-v2, x86-64-v3
- Endianness: little-endian

- Operating system: macOS 26.0
- Architecture: AArch64
- ISA: ARMv8.0-A, ARMv9.0-A
- Endianness: little-endian

- Operating system: Windows 11
- Architecture: x86-64
- ISA: x86-64-v1, x86-64-v2, x86-64-v3
- Endianness: little-endian

- Operating system: Windows 11
- Architecture: AArch64
- ISA: ARMv8.0-A, ARMv9.0-A
- Endianness: little-endian

## Toolchain

- Go 1.27
- GNU Make 4.4
- go test 1.27
- Go race detector 1.27
- Go coverage 1.27
- gofmt 1.27
- go vet 1.27
- golang.org/x/tools/cmd/goimports 0.52
- golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow 0.52
- golang.org/x/vuln/cmd/govulncheck 1.9

## Devcontainer

The development environment is configured in `.devcontainer/`. Manage it from the repository root on the host using the Makefile targets or directly through the `devcontainer`, `docker` and `docker compose` CLIs.

Use an available shell. Add `-eu` for sh or `-Eeuo pipefail` for Bash as needed.

```sh
# start
make up

# workspace command
devcontainer exec --workspace-folder . COMMAND ARG...

# workspace sh
devcontainer exec --workspace-folder . sh -c 'COMMAND ARG... | COMMAND ARG...'

# workspace bash
devcontainer exec --workspace-folder . bash -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar command
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE COMMAND ARG...

# sidecar sh
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE sh -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar bash
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE bash -c 'COMMAND ARG... | COMMAND ARG...'
```

### Services

`devcontainer` — `docker.io/library/ubuntu:26.04` Runs development tools and workspace commands.

`wiremock` — `docker.io/wiremock/wiremock:3.13.2` Mocks HTTP for development and automated tests.

## EditorConfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
max_line_length = off
quote_type = single
trim_trailing_whitespace = true

[*.go]
indent_size = tab
indent_style = tab
tab_width = 8

[Makefile]
indent_size = tab
indent_style = tab
tab_width = 8
```

## Prettier

```js
import xml from '@prettier/plugin-xml';

export default Object.freeze({
    arrowParens: 'always',
    bracketSameLine: false,
    bracketSpacing: true,
    checkIgnorePragma: false,
    embeddedLanguageFormatting: 'auto',
    experimentalOperatorPosition: 'end',
    experimentalTernaries: false,
    htmlWhitespaceSensitivity: 'strict',
    insertPragma: false,
    jsxSingleQuote: false,
    objectWrap: 'preserve',
    plugins: Object.freeze([xml]),
    proseWrap: 'never',
    quoteProps: 'consistent',
    requirePragma: false,
    semi: true,
    singleAttributePerLine: true,
    singleQuote: true,
    trailingComma: 'all',
    vueIndentScriptAndStyle: true,
    xmlQuoteAttributes: 'double',
    xmlSelfClosingSpace: true,
    xmlSortAttributesByKey: false,
    xmlWhitespaceSensitivity: 'strict',
});
```
