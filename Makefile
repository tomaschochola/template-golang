# Makefile
SHELL := bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

# Default
.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Specify a target explicitly.' >&2
	exit 1

# Variables
COMPOSE_PROJECT_NAME := $(shell printf 'dc-%s-%s' "$$(basename -- "$$(pwd -P)" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cs 'a-z0-9' '-' | sed -e 's/^-*//' -e 's/-*$$//' -e 's/^$$/workspace/' | cut -c 1-32 | sed 's/-*$$//')" "$$(printf '%s' "$$(pwd -P)" | sha256sum | cut -c 1-16)")
GOTOOLCHAIN := local
GOWORK := off
LC_ALL := C.UTF-8
SOURCE_DATE_EPOCH := $(shell git log -1 --format=%ct 2>/dev/null || echo 0)
VERSION := $(shell v=$$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0); v=$${v#v}; echo "$$v")

bindir ?= $(exec_prefix)/bin
DESTDIR ?=
exec_prefix ?= $(prefix)
prefix ?= /usr/local
SUDO ?= sudo

export COMPOSE_PROJECT_NAME
export GOTOOLCHAIN
export GOWORK
export LC_ALL
export SOURCE_DATE_EPOCH
export VERSION

# Phony
.PHONY: all
all: build_linux_amd64_v1 build_linux_amd64_v2 build_linux_amd64_v3 build_linux_arm64_v8 build_linux_arm64_v9 build_darwin_amd64_v1 build_darwin_amd64_v2 build_darwin_amd64_v3 build_darwin_arm64_v8 build_darwin_arm64_v9 build_windows_amd64_v1 build_windows_amd64_v2 build_windows_amd64_v3 build_windows_arm64_v8 build_windows_arm64_v9 release

.PHONY: analyze
analyze: npm_check go_mod_check go_list_check go_fix_check go_vet_check shadow_check

.PHONY: audit
audit: npm_audit go_audit

.PHONY: bench
bench: ./go.mod ./go.sum
	go test -run='^$$' -bench=. -benchmem -count=5 -fullpath ./...

.PHONY: build_darwin_amd64_v1
build_darwin_amd64_v1: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v1 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v1/template-golang ./cmd/template-golang

.PHONY: build_darwin_amd64_v2
build_darwin_amd64_v2: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v2 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v2/template-golang ./cmd/template-golang

.PHONY: build_darwin_amd64_v3
build_darwin_amd64_v3: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v3 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v3/template-golang ./cmd/template-golang

.PHONY: build_darwin_arm64_v8
build_darwin_arm64_v8: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GOARM64=v8.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-arm64-v8.0/template-golang ./cmd/template-golang

.PHONY: build_darwin_arm64_v9
build_darwin_arm64_v9: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GOARM64=v9.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-arm64-v9.0/template-golang ./cmd/template-golang

.PHONY: build_linux_amd64_v1
build_linux_amd64_v1: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v1 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v1/template-golang ./cmd/template-golang

.PHONY: build_linux_amd64_v2
build_linux_amd64_v2: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v2 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v2/template-golang ./cmd/template-golang

.PHONY: build_linux_amd64_v3
build_linux_amd64_v3: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v3 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v3/template-golang ./cmd/template-golang

.PHONY: build_linux_arm64_v8
build_linux_arm64_v8: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GOARM64=v8.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-arm64-v8.0/template-golang ./cmd/template-golang

.PHONY: build_linux_arm64_v9
build_linux_arm64_v9: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GOARM64=v9.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-arm64-v9.0/template-golang ./cmd/template-golang

.PHONY: build_windows_amd64_v1
build_windows_amd64_v1: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 GOAMD64=v1 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/windows-amd64-v1/template-golang.exe ./cmd/template-golang

.PHONY: build_windows_amd64_v2
build_windows_amd64_v2: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 GOAMD64=v2 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/windows-amd64-v2/template-golang.exe ./cmd/template-golang

.PHONY: build_windows_amd64_v3
build_windows_amd64_v3: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 GOAMD64=v3 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/windows-amd64-v3/template-golang.exe ./cmd/template-golang

.PHONY: build_windows_arm64_v8
build_windows_arm64_v8: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 GOARM64=v8.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/windows-arm64-v8.0/template-golang.exe ./cmd/template-golang

.PHONY: build_windows_arm64_v9
build_windows_arm64_v9: ./go.mod ./go.sum
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 GOARM64=v9.0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/windows-arm64-v9.0/template-golang.exe ./cmd/template-golang

.PHONY: check
check: doctor lint analyze test coverage audit

.PHONY: clean
clean:
	rm --force --recursive --one-file-system -- ./build ./dist ./temp ./temporary ./tmp ./.temp ./.temporary ./.tmp

.PHONY: coverage
coverage: ./go.mod ./go.sum
	rm --force --recursive --one-file-system -- ./build/coverage
	mkdir --parents -- ./build/coverage/html
	go test -tags=integration -count=1 -fullpath -covermode=atomic -coverpkg=./... -coverprofile=./build/coverage/coverage.out ./...
	go tool cover -func=./build/coverage/coverage.out
	go tool cover -html=./build/coverage/coverage.out -o ./build/coverage/html/index.html

.PHONY: deps_clean
deps_clean: npm_clean

.PHONY: deps_install
deps_install: npm_install go_mod_download

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker compose -f "./.devcontainer/docker-compose.yml" config --quiet
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

.PHONY: dirclean
dirclean:
	fd --hidden --exclude .git --type directory --print0 | sort --zero-terminated --reverse | xargs --null --no-run-if-empty rmdir --ignore-fail-on-non-empty --

.PHONY: dist
dist: dist_release dist_linux_amd64_v1 dist_linux_amd64_v2 dist_linux_amd64_v3 dist_linux_arm64_v8 dist_linux_arm64_v9 dist_darwin_amd64_v1 dist_darwin_amd64_v2 dist_darwin_amd64_v3 dist_darwin_arm64_v8 dist_darwin_arm64_v9 dist_windows_amd64_v1 dist_windows_amd64_v2 dist_windows_amd64_v3 dist_windows_arm64_v8 dist_windows_arm64_v9

.PHONY: dist_darwin_amd64_v1
dist_darwin_amd64_v1: build_darwin_amd64_v1
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v1"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v1" "./build/package/template-golang-$(VERSION)-darwin-amd64-v1/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v1/template-golang "./build/package/template-golang-$(VERSION)-darwin-amd64-v1/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-darwin-amd64-v1/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-darwin-amd64-v1.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-darwin-amd64-v1" "template-golang-$(VERSION)-darwin-amd64-v1/LICENSE" "template-golang-$(VERSION)-darwin-amd64-v1/bin" "template-golang-$(VERSION)-darwin-amd64-v1/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-darwin-amd64-v1.tar.gz" > "template-golang-$(VERSION)-darwin-amd64-v1.tar.gz.sha256"

.PHONY: dist_darwin_amd64_v2
dist_darwin_amd64_v2: build_darwin_amd64_v2
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v2"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v2" "./build/package/template-golang-$(VERSION)-darwin-amd64-v2/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v2/template-golang "./build/package/template-golang-$(VERSION)-darwin-amd64-v2/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-darwin-amd64-v2/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-darwin-amd64-v2.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-darwin-amd64-v2" "template-golang-$(VERSION)-darwin-amd64-v2/LICENSE" "template-golang-$(VERSION)-darwin-amd64-v2/bin" "template-golang-$(VERSION)-darwin-amd64-v2/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-darwin-amd64-v2.tar.gz" > "template-golang-$(VERSION)-darwin-amd64-v2.tar.gz.sha256"

.PHONY: dist_darwin_amd64_v3
dist_darwin_amd64_v3: build_darwin_amd64_v3
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v3"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-darwin-amd64-v3" "./build/package/template-golang-$(VERSION)-darwin-amd64-v3/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-amd64-v3/template-golang "./build/package/template-golang-$(VERSION)-darwin-amd64-v3/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-darwin-amd64-v3/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-darwin-amd64-v3.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-darwin-amd64-v3" "template-golang-$(VERSION)-darwin-amd64-v3/LICENSE" "template-golang-$(VERSION)-darwin-amd64-v3/bin" "template-golang-$(VERSION)-darwin-amd64-v3/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-darwin-amd64-v3.tar.gz" > "template-golang-$(VERSION)-darwin-amd64-v3.tar.gz.sha256"

.PHONY: dist_darwin_arm64_v8
dist_darwin_arm64_v8: build_darwin_arm64_v8
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-darwin-arm64-v8.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-darwin-arm64-v8.0" "./build/package/template-golang-$(VERSION)-darwin-arm64-v8.0/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-arm64-v8.0/template-golang "./build/package/template-golang-$(VERSION)-darwin-arm64-v8.0/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-darwin-arm64-v8.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-darwin-arm64-v8.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-darwin-arm64-v8.0" "template-golang-$(VERSION)-darwin-arm64-v8.0/LICENSE" "template-golang-$(VERSION)-darwin-arm64-v8.0/bin" "template-golang-$(VERSION)-darwin-arm64-v8.0/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-darwin-arm64-v8.0.tar.gz" > "template-golang-$(VERSION)-darwin-arm64-v8.0.tar.gz.sha256"

.PHONY: dist_darwin_arm64_v9
dist_darwin_arm64_v9: build_darwin_arm64_v9
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-darwin-arm64-v9.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-darwin-arm64-v9.0" "./build/package/template-golang-$(VERSION)-darwin-arm64-v9.0/bin" ./dist
	install --mode=0755 -- ./build/bin/darwin-arm64-v9.0/template-golang "./build/package/template-golang-$(VERSION)-darwin-arm64-v9.0/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-darwin-arm64-v9.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-darwin-arm64-v9.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-darwin-arm64-v9.0" "template-golang-$(VERSION)-darwin-arm64-v9.0/LICENSE" "template-golang-$(VERSION)-darwin-arm64-v9.0/bin" "template-golang-$(VERSION)-darwin-arm64-v9.0/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-darwin-arm64-v9.0.tar.gz" > "template-golang-$(VERSION)-darwin-arm64-v9.0.tar.gz.sha256"

.PHONY: dist_linux_amd64_v1
dist_linux_amd64_v1: build_linux_amd64_v1
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-linux-amd64-v1"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-linux-amd64-v1" "./build/package/template-golang-$(VERSION)-linux-amd64-v1/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v1/template-golang "./build/package/template-golang-$(VERSION)-linux-amd64-v1/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-linux-amd64-v1/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-linux-amd64-v1.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-linux-amd64-v1" "template-golang-$(VERSION)-linux-amd64-v1/LICENSE" "template-golang-$(VERSION)-linux-amd64-v1/bin" "template-golang-$(VERSION)-linux-amd64-v1/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-linux-amd64-v1.tar.gz" > "template-golang-$(VERSION)-linux-amd64-v1.tar.gz.sha256"

.PHONY: dist_linux_amd64_v2
dist_linux_amd64_v2: build_linux_amd64_v2
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-linux-amd64-v2"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-linux-amd64-v2" "./build/package/template-golang-$(VERSION)-linux-amd64-v2/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v2/template-golang "./build/package/template-golang-$(VERSION)-linux-amd64-v2/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-linux-amd64-v2/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-linux-amd64-v2.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-linux-amd64-v2" "template-golang-$(VERSION)-linux-amd64-v2/LICENSE" "template-golang-$(VERSION)-linux-amd64-v2/bin" "template-golang-$(VERSION)-linux-amd64-v2/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-linux-amd64-v2.tar.gz" > "template-golang-$(VERSION)-linux-amd64-v2.tar.gz.sha256"

.PHONY: dist_linux_amd64_v3
dist_linux_amd64_v3: build_linux_amd64_v3
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-linux-amd64-v3"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-linux-amd64-v3" "./build/package/template-golang-$(VERSION)-linux-amd64-v3/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v3/template-golang "./build/package/template-golang-$(VERSION)-linux-amd64-v3/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-linux-amd64-v3/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-linux-amd64-v3.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-linux-amd64-v3" "template-golang-$(VERSION)-linux-amd64-v3/LICENSE" "template-golang-$(VERSION)-linux-amd64-v3/bin" "template-golang-$(VERSION)-linux-amd64-v3/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-linux-amd64-v3.tar.gz" > "template-golang-$(VERSION)-linux-amd64-v3.tar.gz.sha256"

.PHONY: dist_linux_arm64_v8
dist_linux_arm64_v8: build_linux_arm64_v8
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-linux-arm64-v8.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-linux-arm64-v8.0" "./build/package/template-golang-$(VERSION)-linux-arm64-v8.0/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-arm64-v8.0/template-golang "./build/package/template-golang-$(VERSION)-linux-arm64-v8.0/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-linux-arm64-v8.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-linux-arm64-v8.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-linux-arm64-v8.0" "template-golang-$(VERSION)-linux-arm64-v8.0/LICENSE" "template-golang-$(VERSION)-linux-arm64-v8.0/bin" "template-golang-$(VERSION)-linux-arm64-v8.0/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-linux-arm64-v8.0.tar.gz" > "template-golang-$(VERSION)-linux-arm64-v8.0.tar.gz.sha256"

.PHONY: dist_linux_arm64_v9
dist_linux_arm64_v9: build_linux_arm64_v9
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-linux-arm64-v9.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-linux-arm64-v9.0" "./build/package/template-golang-$(VERSION)-linux-arm64-v9.0/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-arm64-v9.0/template-golang "./build/package/template-golang-$(VERSION)-linux-arm64-v9.0/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-linux-arm64-v9.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-linux-arm64-v9.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-linux-arm64-v9.0" "template-golang-$(VERSION)-linux-arm64-v9.0/LICENSE" "template-golang-$(VERSION)-linux-arm64-v9.0/bin" "template-golang-$(VERSION)-linux-arm64-v9.0/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-linux-arm64-v9.0.tar.gz" > "template-golang-$(VERSION)-linux-arm64-v9.0.tar.gz.sha256"

.PHONY: dist_release
dist_release: release
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-release"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-release" "./build/package/template-golang-$(VERSION)-release/bin" ./dist
	install --mode=0755 -- ./build/bin/release/template-golang "./build/package/template-golang-$(VERSION)-release/bin/template-golang"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-release/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-release.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-release" "template-golang-$(VERSION)-release/LICENSE" "template-golang-$(VERSION)-release/bin" "template-golang-$(VERSION)-release/bin/template-golang"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-release.tar.gz" > "template-golang-$(VERSION)-release.tar.gz.sha256"

.PHONY: dist_windows_amd64_v1
dist_windows_amd64_v1: build_windows_amd64_v1
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-windows-amd64-v1"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-windows-amd64-v1" "./build/package/template-golang-$(VERSION)-windows-amd64-v1/bin" ./dist
	install --mode=0755 -- ./build/bin/windows-amd64-v1/template-golang.exe "./build/package/template-golang-$(VERSION)-windows-amd64-v1/bin/template-golang.exe"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-windows-amd64-v1/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-windows-amd64-v1.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-windows-amd64-v1" "template-golang-$(VERSION)-windows-amd64-v1/LICENSE" "template-golang-$(VERSION)-windows-amd64-v1/bin" "template-golang-$(VERSION)-windows-amd64-v1/bin/template-golang.exe"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-windows-amd64-v1.tar.gz" > "template-golang-$(VERSION)-windows-amd64-v1.tar.gz.sha256"

.PHONY: dist_windows_amd64_v2
dist_windows_amd64_v2: build_windows_amd64_v2
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-windows-amd64-v2"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-windows-amd64-v2" "./build/package/template-golang-$(VERSION)-windows-amd64-v2/bin" ./dist
	install --mode=0755 -- ./build/bin/windows-amd64-v2/template-golang.exe "./build/package/template-golang-$(VERSION)-windows-amd64-v2/bin/template-golang.exe"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-windows-amd64-v2/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-windows-amd64-v2.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-windows-amd64-v2" "template-golang-$(VERSION)-windows-amd64-v2/LICENSE" "template-golang-$(VERSION)-windows-amd64-v2/bin" "template-golang-$(VERSION)-windows-amd64-v2/bin/template-golang.exe"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-windows-amd64-v2.tar.gz" > "template-golang-$(VERSION)-windows-amd64-v2.tar.gz.sha256"

.PHONY: dist_windows_amd64_v3
dist_windows_amd64_v3: build_windows_amd64_v3
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-windows-amd64-v3"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-windows-amd64-v3" "./build/package/template-golang-$(VERSION)-windows-amd64-v3/bin" ./dist
	install --mode=0755 -- ./build/bin/windows-amd64-v3/template-golang.exe "./build/package/template-golang-$(VERSION)-windows-amd64-v3/bin/template-golang.exe"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-windows-amd64-v3/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-windows-amd64-v3.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-windows-amd64-v3" "template-golang-$(VERSION)-windows-amd64-v3/LICENSE" "template-golang-$(VERSION)-windows-amd64-v3/bin" "template-golang-$(VERSION)-windows-amd64-v3/bin/template-golang.exe"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-windows-amd64-v3.tar.gz" > "template-golang-$(VERSION)-windows-amd64-v3.tar.gz.sha256"

.PHONY: dist_windows_arm64_v8
dist_windows_arm64_v8: build_windows_arm64_v8
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-windows-arm64-v8.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-windows-arm64-v8.0" "./build/package/template-golang-$(VERSION)-windows-arm64-v8.0/bin" ./dist
	install --mode=0755 -- ./build/bin/windows-arm64-v8.0/template-golang.exe "./build/package/template-golang-$(VERSION)-windows-arm64-v8.0/bin/template-golang.exe"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-windows-arm64-v8.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-windows-arm64-v8.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-windows-arm64-v8.0" "template-golang-$(VERSION)-windows-arm64-v8.0/LICENSE" "template-golang-$(VERSION)-windows-arm64-v8.0/bin" "template-golang-$(VERSION)-windows-arm64-v8.0/bin/template-golang.exe"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-windows-arm64-v8.0.tar.gz" > "template-golang-$(VERSION)-windows-arm64-v8.0.tar.gz.sha256"

.PHONY: dist_windows_arm64_v9
dist_windows_arm64_v9: build_windows_arm64_v9
	rm --force --recursive --one-file-system -- "./build/package/template-golang-$(VERSION)-windows-arm64-v9.0"
	install --directory --mode=0755 -- "./build/package/template-golang-$(VERSION)-windows-arm64-v9.0" "./build/package/template-golang-$(VERSION)-windows-arm64-v9.0/bin" ./dist
	install --mode=0755 -- ./build/bin/windows-arm64-v9.0/template-golang.exe "./build/package/template-golang-$(VERSION)-windows-arm64-v9.0/bin/template-golang.exe"
	install --mode=0644 -- ./LICENSE "./build/package/template-golang-$(VERSION)-windows-arm64-v9.0/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-golang-$(VERSION)-windows-arm64-v9.0.tar.gz" --directory=./build/package --no-recursion -- "template-golang-$(VERSION)-windows-arm64-v9.0" "template-golang-$(VERSION)-windows-arm64-v9.0/LICENSE" "template-golang-$(VERSION)-windows-arm64-v9.0/bin" "template-golang-$(VERSION)-windows-arm64-v9.0/bin/template-golang.exe"
	cd ./dist && sha256sum -- "template-golang-$(VERSION)-windows-arm64-v9.0.tar.gz" > "template-golang-$(VERSION)-windows-arm64-v9.0.tar.gz.sha256"

.PHONY: distclean
distclean: clean deps_clean

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor npm_check toolchain_check

.PHONY: down
down:
	docker compose -f "./.devcontainer/docker-compose.yml" down --remove-orphans

.PHONY: fix
fix: go_fix goimports_fix gofmt_fix go_mod_fix prettier_fix trimmer_fix

.PHONY: fuzz
fuzz: ./go.mod ./go.sum
	go test -run='^$$' -fullpath -fuzz='^FuzzTodo$$' -fuzztime=10s ./internal/app

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: go_audit
go_audit: go_audit_module go_audit_package go_audit_symbol

.PHONY: go_audit_module
go_audit_module: go_mod_download
	go tool govulncheck -C ./cmd/template-golang -scan=module -show=version

.PHONY: go_audit_package
go_audit_package: go_mod_download
	go tool govulncheck -scan=package -test -show=version ./...

.PHONY: go_audit_symbol
go_audit_symbol: go_mod_download
	go tool govulncheck -scan=symbol -test -show=version ./...

.PHONY: go_fix
go_fix: ./go.mod ./go.sum
	go fix ./...

.PHONY: go_fix_check
go_fix_check:
	go fix -diff ./...

.PHONY: go_list_check
go_list_check:
	go list -deps -test ./... >/dev/null

.PHONY: go_mod_check
go_mod_check:
	go mod tidy -diff

.PHONY: go_mod_download
go_mod_download: ./go.mod ./go.sum
	go mod download
	go mod verify

.PHONY: go_mod_fix
go_mod_fix: ./go.mod ./go.sum
	go mod tidy

.PHONY: go_update
go_update: ./go.mod ./go.sum
	go get -u -t ./...
	go get -u tool
	go mod tidy
	go mod verify

.PHONY: go_vet_check
go_vet_check:
	go vet ./...

.PHONY: gofmt_check
gofmt_check:
	out=$$(gofmt -e -s -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

.PHONY: gofmt_fix
gofmt_fix: ./go.mod ./go.sum
	gofmt -e -s -w .

.PHONY: goimports_check
goimports_check:
	out=$$(go tool goimports -e -local "$$(go list -m)" -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

.PHONY: goimports_fix
goimports_fix: ./go.mod ./go.sum
	go tool goimports -e -local "$$(go list -m)" -w .

.PHONY: install
install: release installdirs
	$(SUDO) install --mode=0755 -- "./build/bin/release/template-golang" "$(DESTDIR)$(bindir)/template-golang"

.PHONY: installcheck
installcheck:
	test -f "$(DESTDIR)$(bindir)/template-golang"
	test -x "$(DESTDIR)$(bindir)/template-golang"

.PHONY: installdirs
installdirs:
	$(SUDO) install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: interactive_gate
.SILENT: interactive_gate
interactive_gate:
	if test ! -t 0 || test ! -t 1; then printf '%s\n' 'interactive_gate: interactive only' >&2; exit 1; fi

.PHONY: lint
lint: gofmt_check goimports_check prettier_check trimmer_check

.PHONY: npm_audit
npm_audit: npm_config_check ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=critical --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_check
npm_check: npm_config_check ./node_modules/.package-lock.json
	npm ci --dry-run --ignore-scripts --audit=false --install-links --include=prod --include=dev --include=peer --include=optional
	npm ls --all --install-links --include=prod --include=dev --include=peer --include=optional >/dev/null

.PHONY: npm_clean
npm_clean:
	rm --force --recursive --one-file-system -- ./node_modules

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

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: nuke
nuke: distclean prune xfd dirclean

.PHONY: port ports url urls
.SILENT: port ports url urls
port ports url urls:
	printf 'Project: %s\n' "$$COMPOSE_PROJECT_NAME"
	printf '%-20s %-12s %s\n' 'SERVICE' 'PORT' 'URL'
	docker compose -f "./.devcontainer/docker-compose.yml" ps --format '{{$$service := .Service}}{{range .Publishers}}{{if .PublishedPort}}{{printf "%-20s %-12s http://%s:%d" $$service (printf "%d/%s" .TargetPort .Protocol) .URL .PublishedPort}}{{println}}{{end}}{{end}}' | sed '/^$$/d' | sort

.PHONY: postcreate
postcreate: deps_install toolchain_check

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -c .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -w .

.PHONY: prune
prune:
	docker compose -f "./.devcontainer/docker-compose.yml" down --volumes --rmi local --remove-orphans

.PHONY: race
race: ./go.mod ./go.sum
	go test -tags=integration -race -count=1 -shuffle=on -cpu=1,2,4,8 -fullpath ./...

.PHONY: rebuild
rebuild: devcontainer_check down | $(CURDIR)/.tmp
	TMPDIR="$(CURDIR)/.tmp" devcontainer up --workspace-folder . --build-no-cache

.PHONY: release
release: ./go.mod ./go.sum
	CGO_ENABLED=0 go build -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/release/template-golang ./cmd/template-golang

.PHONY: shadow_check
shadow_check: ./go.mod ./go.sum
	go tool shadow ./...

.PHONY: shell
shell: interactive_gate up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop:
	docker compose -f "./.devcontainer/docker-compose.yml" stop

.PHONY: test
test: ./go.mod ./go.sum
	go test -tags=integration -race -count=1 -shuffle=on -fullpath ./...

.PHONY: toolchain_check
toolchain_check: ./go.mod
	go version

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer check .

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer fix .

.PHONY: uninstall
uninstall:
	$(SUDO) rm --force -- "$(DESTDIR)$(bindir)/template-golang"

.PHONY: up
up: devcontainer_check | $(CURDIR)/.tmp
	TMPDIR="$(CURDIR)/.tmp" devcontainer up --workspace-folder .

.PHONY: update
update: npm_config_check npm_update go_update

.PHONY: xfd
xfd:
	git clean -Xfd

# Non-phony
$(CURDIR)/.tmp:
	mkdir --parents -- "$@"

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
