# Makefile

SHELL := /usr/bin/env bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

# Default goal

.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Run an explicit target' >&2
	exit 1

# Options

COMPOSE_PROJECT_NAME ?= template-golang-$(shell pwd -P | sha256sum | cut -c1-16)
DESTDIR ?=
VERSION ?= $(shell v=$$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0); v=$${v#v}; echo "$$v")
SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct 2>/dev/null || echo 0)
prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin
SUDO ?= sudo

DEVCONTAINER_COMPOSE := ./.devcontainer/docker-compose.yml
DEVCONTAINER_TMPDIR := $(CURDIR)/.devcontainer/.tmp
LC_ALL := C.UTF-8
PROGRAM := template-golang
GOWORK := off
PACKAGE_LINUX_AMD64_V1 := $(PROGRAM)-$(VERSION)-linux-amd64-v1
PACKAGE_LINUX_AMD64_V2 := $(PROGRAM)-$(VERSION)-linux-amd64-v2
PACKAGE_LINUX_AMD64_V3 := $(PROGRAM)-$(VERSION)-linux-amd64-v3
PACKAGE_LINUX_ARM64_V8 := $(PROGRAM)-$(VERSION)-linux-arm64-v8.0
PACKAGE_LINUX_ARM64_V9 := $(PROGRAM)-$(VERSION)-linux-arm64-v9.0
PACKAGE_DARWIN_AMD64_V1 := $(PROGRAM)-$(VERSION)-darwin-amd64-v1
PACKAGE_DARWIN_AMD64_V2 := $(PROGRAM)-$(VERSION)-darwin-amd64-v2
PACKAGE_DARWIN_AMD64_V3 := $(PROGRAM)-$(VERSION)-darwin-amd64-v3
PACKAGE_DARWIN_ARM64_V8 := $(PROGRAM)-$(VERSION)-darwin-arm64-v8.0
PACKAGE_DARWIN_ARM64_V9 := $(PROGRAM)-$(VERSION)-darwin-arm64-v9.0

export LC_ALL
export VERSION
export SOURCE_DATE_EPOCH
export GOWORK
export COMPOSE_PROJECT_NAME

# Public goals

.PHONY: fix
fix: go_fix goimports_fix gofmt_fix go_mod_fix prettier_fix trimmer_fix

.PHONY: check
check: devcontainer_gate doctor lint analyze test coverage audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor npm_check toolchain_check

.PHONY: lint
lint: gofmt_check goimports_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check go_mod_check go_list_check go_fix_check go_vet_check shadow_check

.PHONY: test
test: devcontainer_gate ./go.mod ./go.sum
	go test -mod=readonly -race -count=1 -shuffle=on -cpu=1,2,4,8 -timeout=2m -fullpath ./...

.PHONY: fuzz
fuzz: devcontainer_gate ./go.mod ./go.sum
	go test -mod=readonly -run='^$$' -fuzz='^FuzzTodo$$' -fuzztime=10s -timeout=2m -fullpath ./internal/app

.PHONY: bench
bench: devcontainer_gate ./go.mod ./go.sum
	go test -mod=readonly -run='^$$' -bench=. -benchmem -count=5 -timeout=2m -fullpath ./...

.PHONY: coverage
coverage: devcontainer_gate ./go.mod ./go.sum
	rm --force --recursive --one-file-system -- ./build/coverage
	mkdir --parents -- ./build/coverage/html
	go test -mod=readonly -count=1 -timeout=2m -fullpath -covermode=atomic -coverpkg=./internal/... -coverprofile=./build/coverage/coverage.out ./internal/...
	go tool cover -func=./build/coverage/coverage.out
	go tool cover -html=./build/coverage/coverage.out -o ./build/coverage/html/index.html

.PHONY: audit
audit: npm_audit go_audit

.PHONY: update
update: npm_config_check npm_update go_update

.PHONY: clean
clean:
	rm --force --recursive --one-file-system -- ./build ./dist "$(DEVCONTAINER_TMPDIR)"

.PHONY: distclean
distclean: clean deps_clean

.PHONY: all
all: build_linux_amd64_v1 build_linux_amd64_v2 build_linux_amd64_v3 build_linux_arm64_v8 build_linux_arm64_v9 build_darwin_amd64_v1 build_darwin_amd64_v2 build_darwin_amd64_v3 build_darwin_arm64_v8 build_darwin_arm64_v9 native

.PHONY: installdirs
installdirs:
	$(SUDO) install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: install
install: native installdirs
	$(SUDO) install --mode=0755 -- "./build/bin/native/$(PROGRAM)" "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: uninstall
uninstall:
	$(SUDO) rm --force -- "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: installcheck
installcheck:
	test -f "$(DESTDIR)$(bindir)/$(PROGRAM)"
	test -x "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: dist
dist: all dist_linux_amd64_v1 dist_linux_amd64_v2 dist_linux_amd64_v3 dist_linux_arm64_v8 dist_linux_arm64_v9 dist_darwin_amd64_v1 dist_darwin_amd64_v2 dist_darwin_amd64_v3 dist_darwin_arm64_v8 dist_darwin_arm64_v9
	cd ./dist && sha256sum -- "$(PACKAGE_LINUX_AMD64_V1).tar.gz" "$(PACKAGE_LINUX_AMD64_V2).tar.gz" "$(PACKAGE_LINUX_AMD64_V3).tar.gz" "$(PACKAGE_LINUX_ARM64_V8).tar.gz" "$(PACKAGE_LINUX_ARM64_V9).tar.gz" "$(PACKAGE_DARWIN_AMD64_V1).tar.gz" "$(PACKAGE_DARWIN_AMD64_V2).tar.gz" "$(PACKAGE_DARWIN_AMD64_V3).tar.gz" "$(PACKAGE_DARWIN_ARM64_V8).tar.gz" "$(PACKAGE_DARWIN_ARM64_V9).tar.gz" > ./SHA256SUMS

.PHONY: postcreate
postcreate: deps_install toolchain_check

.PHONY: up
up: host_gate devcontainer_check
	mkdir --parents -- "$(DEVCONTAINER_TMPDIR)"
	env TMPDIR="$(DEVCONTAINER_TMPDIR)" devcontainer up --workspace-folder .

.PHONY: shell
shell: interactive_gate host_gate up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" stop

.PHONY: down
down: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" down --remove-orphans

.PHONY: rebuild
rebuild: host_gate devcontainer_check down
	mkdir --parents -- "$(DEVCONTAINER_TMPDIR)"
	env TMPDIR="$(DEVCONTAINER_TMPDIR)" devcontainer up --workspace-folder . --build-no-cache

.PHONY: nuke
nuke: distclean prune

.PHONY: prune
prune: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" down --volumes --rmi all --remove-orphans

# Protected goals

.PHONY: host_gate
.SILENT: host_gate
host_gate:
	if test -e /.dockerenv; then printf '%s\n' 'host_gate: host only' >&2; exit 1; fi

.PHONY: devcontainer_gate
.SILENT: devcontainer_gate
devcontainer_gate:
	if test ! -e /.dockerenv; then printf '%s\n' 'devcontainer_gate: devcontainer only' >&2; exit 1; fi

.PHONY: interactive_gate
.SILENT: interactive_gate
interactive_gate:
	if test ! -t 0 || test ! -t 1; then printf '%s\n' 'interactive_gate: interactive only' >&2; exit 1; fi

.PHONY: deps_install
deps_install: npm_install go_mod_download

.PHONY: deps_clean
deps_clean: npm_clean

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer check .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -w .

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -c .

.PHONY: npm_config_check
npm_config_check: ./.npmrc
	test "$$(npm config get ignore-scripts)" = "true"
	test "$$(npm config get allow-directory)" = "root"
	test "$$(npm config get allow-file)" = "root"
	test "$$(npm config get allow-git)" = "root"
	test "$$(npm config get allow-remote)" = "root"
	test "$$(npm config get audit)" = "false"
	test "$$(npm config get strict-ssl)" = "true"
	test "$$(npm config get registry)" = "https://registry.npmjs.org/"

.PHONY: npm_doctor
npm_doctor:
	npm doctor connection registry environment permissions cache

.PHONY: npm_check
npm_check: npm_config_check ./node_modules/.package-lock.json
	npm ci --dry-run --ignore-scripts --audit=false --install-links --include=prod --include=dev --include=peer --include=optional
	npm ls --all --install-links --include=prod --include=dev --include=peer --include=optional >/dev/null

.PHONY: npm_audit
npm_audit: npm_config_check ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=moderate --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_clean
npm_clean:
	rm --force --recursive --one-file-system -- ./node_modules

.PHONY: go_mod_download
go_mod_download: ./go.mod ./go.sum
	go mod download
	go mod verify

.PHONY: go_update
go_update: ./go.mod ./go.sum
	go get -u -t ./...
	go get tool
	go mod tidy

.PHONY: go_fix
go_fix: ./go.mod ./go.sum
	go fix ./...

.PHONY: go_mod_fix
go_mod_fix: ./go.mod ./go.sum
	go mod tidy

.PHONY: gofmt_fix
gofmt_fix: ./go.mod ./go.sum
	gofmt -e -s -w .

.PHONY: goimports_fix
goimports_fix: ./go.mod ./go.sum
	go tool goimports -e -local "$$(go list -m)" -w .

.PHONY: toolchain_check
toolchain_check: ./go.mod
	go version

.PHONY: go_mod_check
go_mod_check:
	go mod tidy -diff

.PHONY: gofmt_check
gofmt_check:
	out=$$(gofmt -e -s -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

.PHONY: goimports_check
goimports_check:
	out=$$(go tool goimports -e -local "$$(go list -m)" -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

.PHONY: go_list_check
go_list_check:
	go list -mod=readonly -deps -test ./... >/dev/null

.PHONY: go_fix_check
go_fix_check:
	go fix -diff ./...

.PHONY: go_vet_check
go_vet_check:
	go vet -mod=readonly ./...

.PHONY: shadow_check
shadow_check: ./go.mod ./go.sum
	go tool shadow ./...

.PHONY: go_audit
go_audit: ./go.mod ./go.sum
	go mod verify
	go tool govulncheck -scan=symbol -test -show=version ./...
	go tool govulncheck -scan=package -show=version tool

.PHONY: build_linux_amd64_v1
build_linux_amd64_v1: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v1 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v1/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v1/$(PROGRAM)

.PHONY: build_linux_amd64_v2
build_linux_amd64_v2: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v2 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v2/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v2/$(PROGRAM)

.PHONY: build_linux_amd64_v3
build_linux_amd64_v3: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v3 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v3/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v3/$(PROGRAM)

.PHONY: build_linux_arm64_v8
build_linux_arm64_v8: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GOARM64=v8.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-arm64-v8.0/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-arm64-v8.0/$(PROGRAM)

.PHONY: build_linux_arm64_v9
build_linux_arm64_v9: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GOARM64=v9.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-arm64-v9.0/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-arm64-v9.0/$(PROGRAM)

.PHONY: build_darwin_amd64_v1
build_darwin_amd64_v1: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v1 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v1/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v1/$(PROGRAM)

.PHONY: build_darwin_amd64_v2
build_darwin_amd64_v2: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v2 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v2/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v2/$(PROGRAM)

.PHONY: build_darwin_amd64_v3
build_darwin_amd64_v3: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v3 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v3/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v3/$(PROGRAM)

.PHONY: build_darwin_arm64_v8
build_darwin_arm64_v8: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GOARM64=v8.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-arm64-v8.0/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-arm64-v8.0/$(PROGRAM)

.PHONY: build_darwin_arm64_v9
build_darwin_arm64_v9: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GOARM64=v9.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-arm64-v9.0/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-arm64-v9.0/$(PROGRAM)

.PHONY: native
native: ./go.mod ./go.sum
	CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/native/$(PROGRAM) ./cmd/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/native/$(PROGRAM)

.PHONY: dist_linux_amd64_v1
dist_linux_amd64_v1: build_linux_amd64_v1
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_AMD64_V1)" "./build/package/$(PACKAGE_LINUX_AMD64_V1)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v1/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V1)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V1).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V1)"

.PHONY: dist_linux_amd64_v2
dist_linux_amd64_v2: build_linux_amd64_v2
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_AMD64_V2)" "./build/package/$(PACKAGE_LINUX_AMD64_V2)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v2/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V2)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V2).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V2)"

.PHONY: dist_linux_amd64_v3
dist_linux_amd64_v3: build_linux_amd64_v3
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_AMD64_V3)" "./build/package/$(PACKAGE_LINUX_AMD64_V3)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v3/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V3)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V3).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V3)"

.PHONY: dist_linux_arm64_v8
dist_linux_arm64_v8: build_linux_arm64_v8
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_ARM64_V8)" "./build/package/$(PACKAGE_LINUX_ARM64_V8)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-arm64-v8.0/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_ARM64_V8)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_ARM64_V8).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_ARM64_V8)"

.PHONY: dist_linux_arm64_v9
dist_linux_arm64_v9: build_linux_arm64_v9
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_ARM64_V9)" "./build/package/$(PACKAGE_LINUX_ARM64_V9)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-arm64-v9.0/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_ARM64_V9)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_ARM64_V9)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_ARM64_V9).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_ARM64_V9)"

.PHONY: dist_darwin_amd64_v1
dist_darwin_amd64_v1: build_darwin_amd64_v1
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_DARWIN_AMD64_V1)" "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v1/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V1).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V1)"

.PHONY: dist_darwin_amd64_v2
dist_darwin_amd64_v2: build_darwin_amd64_v2
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_DARWIN_AMD64_V2)" "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v2/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V2).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V2)"

.PHONY: dist_darwin_amd64_v3
dist_darwin_amd64_v3: build_darwin_amd64_v3
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_DARWIN_AMD64_V3)" "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v3/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V3).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V3)"

.PHONY: dist_darwin_arm64_v8
dist_darwin_arm64_v8: build_darwin_arm64_v8
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_DARWIN_ARM64_V8)" "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-arm64-v8.0/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_V8).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_ARM64_V8)"

.PHONY: dist_darwin_arm64_v9
dist_darwin_arm64_v9: build_darwin_arm64_v9
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_DARWIN_ARM64_V9)" "./build/package/$(PACKAGE_DARWIN_ARM64_V9)/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-arm64-v9.0/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_ARM64_V9)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_ARM64_V9)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_V9).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_ARM64_V9)"

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: devcontainer_check
devcontainer_check: host_gate
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker compose -f "$(DEVCONTAINER_COMPOSE)" config --quiet
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

# Private targets

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
