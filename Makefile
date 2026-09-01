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

DEVCONTAINER_FILTER := label=devcontainer.local_folder=$(CURDIR)

COVERAGE_MIN ?= 100

DESTDIR ?=

PROGRAM := template-golang

ifeq ($(origin SOURCE_DATE_EPOCH), undefined)
SOURCE_DATE_EPOCH := $(shell git log -1 --format=%ct 2>/dev/null)
else
override SOURCE_DATE_EPOCH := $(value SOURCE_DATE_EPOCH)
endif

ifeq ($(origin VERSION), undefined)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null)
else
override VERSION := $(value VERSION)
endif

export SOURCE_DATE_EPOCH
export VERSION

PACKAGE_LINUX_AMD64_V1 := $(PROGRAM)-$(VERSION)-linux-amd64-v1
PACKAGE_LINUX_AMD64_V2 := $(PROGRAM)-$(VERSION)-linux-amd64-v2
PACKAGE_LINUX_AMD64_V3 := $(PROGRAM)-$(VERSION)-linux-amd64-v3
PACKAGE_LINUX_ARM64_V8 := $(PROGRAM)-$(VERSION)-linux-arm64-v8.0
PACKAGE_DARWIN_AMD64_V1 := $(PROGRAM)-$(VERSION)-darwin-amd64-v1
PACKAGE_DARWIN_AMD64_V2 := $(PROGRAM)-$(VERSION)-darwin-amd64-v2
PACKAGE_DARWIN_AMD64_V3 := $(PROGRAM)-$(VERSION)-darwin-amd64-v3
PACKAGE_DARWIN_ARM64_V8 := $(PROGRAM)-$(VERSION)-darwin-arm64-v8.0

prefix ?= /usr/local

bindir ?= $(prefix)/bin

export GOWORK := off

# Public goals

.PHONY: fix
fix: go_fix goimports_fix gofmt_fix go_mod_fix prettier_fix trimmer_fix

.PHONY: check
check: doctor lint analyze test coverage fuzz dist audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor

.PHONY: lint
lint: gofmt_check goimports_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check go_mod_check go_list_check go_fix_check go_vet_check shadow_check

.PHONY: test
test: go_test

.PHONY: coverage
coverage: go_coverage

.PHONY: audit
audit: npm_audit go_audit

.PHONY: update
update: npm_config_check ./package.json ./package-lock.json ./go.mod ./go.sum npm_update go_update

.PHONY: clean
clean:
	rm --force --recursive --one-file-system -- ./build ./dist

.PHONY: distclean
distclean: clean deps_clean

.PHONY: all
all: go_build

.PHONY: installdirs
installdirs:
	install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: install
install: go_build_native installdirs
	install --mode=0755 -- "./build/bin/native/$(PROGRAM)" "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: uninstall
uninstall:
	rm --force -- "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: installcheck
installcheck:
	test "$$("$(DESTDIR)$(bindir)/$(PROGRAM)" first second)" = "$$(printf 'first\nsecond')"

.PHONY: dist
dist: dist_metadata_check all go_dist

.PHONY: benchmark
benchmark: go_benchmark

.PHONY: fuzz
fuzz: go_fuzz

.PHONY: profile
profile: go_profile

.PHONY: postcreate
postcreate: deps_install

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: shell
shell: up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm "$$container"; done

.PHONY: rebuild
rebuild: devcontainer_check down
	devcontainer up --workspace-folder . --build-no-cache

# Protected goals

.PHONY: dist_metadata_check
dist_metadata_check:
	if [[ ! "$${SOURCE_DATE_EPOCH}" =~ ^[0-9]+$$ ]]; then printf '%s\n' 'SOURCE_DATE_EPOCH must contain only decimal digits' >&2; exit 1; fi
	if [[ ! "$${VERSION}" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$$ ]]; then printf '%s\n' 'VERSION contains unsupported characters' >&2; exit 1; fi

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
go_fix:
	go fix ./...

.PHONY: go_mod_fix
go_mod_fix:
	go mod tidy

.PHONY: gofmt_fix
gofmt_fix:
	gofmt -e -s -w .

.PHONY: goimports_fix
goimports_fix:
	go tool goimports -e -local "$$(go list -m)" -w .

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
shadow_check:
	go tool shadow ./...

.PHONY: go_test
go_test:
	go test -mod=readonly -race -count=1 -shuffle=on -cpu=1,2,4,8 -timeout=2m -fullpath ./...

.PHONY: go_coverage
go_coverage:
	rm --force --recursive --one-file-system -- ./build/coverage
	mkdir --parents -- ./build/coverage/html
	go test -mod=readonly -count=1 -timeout=2m -fullpath -covermode=atomic -coverpkg=./internal/... -coverprofile=./build/coverage/coverage.out ./internal/...
	go tool cover -func=./build/coverage/coverage.out
	go tool cover -html=./build/coverage/coverage.out -o ./build/coverage/html/index.html
	go tool cover -func=./build/coverage/coverage.out | awk -v minimum="$(COVERAGE_MIN)" '/^total:/ { coverage = $$3; sub(/%$$/, "", coverage); found = 1 } END { exit !found || coverage + 0 < minimum + 0 }'

.PHONY: go_benchmark
go_benchmark:
	go test -mod=readonly -run='^$$' -bench='.' -benchmem -count=5 -benchtime=1s ./...

.PHONY: go_fuzz
go_fuzz:
	go test -mod=readonly -run='^$$' -fuzz='^FuzzRun$$' -fuzztime=10s ./internal/app

.PHONY: go_profile
go_profile:
	rm --force --recursive --one-file-system -- ./build/profiles
	mkdir --parents -- ./build/profiles/BenchmarkRun
	go test -mod=readonly -run='^$$' -bench='^BenchmarkRun$$' -benchmem -count=1 -benchtime=1s -o ./build/profiles/BenchmarkRun/profile.test -cpuprofile=./build/profiles/BenchmarkRun/cpu.pprof -memprofile=./build/profiles/BenchmarkRun/mem.pprof -blockprofile=./build/profiles/BenchmarkRun/block.pprof -mutexprofile=./build/profiles/BenchmarkRun/mutex.pprof ./internal/app

.PHONY: go_audit
go_audit: all
	go mod verify
	go tool govulncheck -scan=symbol -test -show=version ./...
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v1/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v2/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-amd64-v3/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/linux-arm64-v8.0/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v1/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v2/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-amd64-v3/$(PROGRAM)
	go tool govulncheck -mode=binary -show=version ./build/bin/darwin-arm64-v8.0/$(PROGRAM)

.PHONY: go_build
go_build:
	rm --force --recursive --one-file-system -- ./build/bin
	mkdir --parents -- ./build/bin/linux-amd64-v1 ./build/bin/linux-amd64-v2 ./build/bin/linux-amd64-v3 ./build/bin/linux-arm64-v8.0 ./build/bin/darwin-amd64-v1 ./build/bin/darwin-amd64-v2 ./build/bin/darwin-amd64-v3 ./build/bin/darwin-arm64-v8.0
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v1 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v1/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v2 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v2/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v3 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-amd64-v3/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 GOARM64=v8.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/linux-arm64-v8.0/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v1 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v1/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v2 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v2/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 GOAMD64=v3 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-amd64-v3/$(PROGRAM) ./cmd/$(PROGRAM)
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 GOARM64=v8.0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/darwin-arm64-v8.0/$(PROGRAM) ./cmd/$(PROGRAM)

.PHONY: go_build_native
go_build_native:
	rm --force --recursive --one-file-system -- ./build/bin/native
	mkdir --parents -- ./build/bin/native
	CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -o ./build/bin/native/$(PROGRAM) ./cmd/$(PROGRAM)

.PHONY: go_dist
go_dist: dist_metadata_check
	rm --force --recursive --one-file-system -- ./build/package ./dist
	install --directory --mode=0755 -- "./build/package/$(PACKAGE_LINUX_AMD64_V1)" "./build/package/$(PACKAGE_LINUX_AMD64_V1)/bin" "./build/package/$(PACKAGE_LINUX_AMD64_V2)" "./build/package/$(PACKAGE_LINUX_AMD64_V2)/bin" "./build/package/$(PACKAGE_LINUX_AMD64_V3)" "./build/package/$(PACKAGE_LINUX_AMD64_V3)/bin" "./build/package/$(PACKAGE_LINUX_ARM64_V8)" "./build/package/$(PACKAGE_LINUX_ARM64_V8)/bin" "./build/package/$(PACKAGE_DARWIN_AMD64_V1)" "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/bin" "./build/package/$(PACKAGE_DARWIN_AMD64_V2)" "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/bin" "./build/package/$(PACKAGE_DARWIN_AMD64_V3)" "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/bin" "./build/package/$(PACKAGE_DARWIN_ARM64_V8)" "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/bin" ./dist
	install --mode=0755 -- ./build/bin/linux-amd64-v1/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/linux-amd64-v2/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/linux-amd64-v3/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/linux-arm64-v8.0/$(PROGRAM) "./build/package/$(PACKAGE_LINUX_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/darwin-amd64-v1/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/darwin-amd64-v2/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/darwin-amd64-v3/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0755 -- ./build/bin/darwin-arm64-v8.0/$(PROGRAM) "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V1)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V2)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_AMD64_V3)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_LINUX_ARM64_V8)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V1)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V2)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_AMD64_V3)/LICENSE"
	install --mode=0644 -- ./LICENSE "./build/package/$(PACKAGE_DARWIN_ARM64_V8)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V1).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V1)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V2).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V2)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V3).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_AMD64_V3)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_ARM64_V8).tar.gz" --directory=./build/package -- "$(PACKAGE_LINUX_ARM64_V8)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V1).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V1)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V2).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V2)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V3).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_AMD64_V3)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_V8).tar.gz" --directory=./build/package -- "$(PACKAGE_DARWIN_ARM64_V8)"
	cd ./dist && sha256sum -- "$(PACKAGE_LINUX_AMD64_V1).tar.gz" "$(PACKAGE_LINUX_AMD64_V2).tar.gz" "$(PACKAGE_LINUX_AMD64_V3).tar.gz" "$(PACKAGE_LINUX_ARM64_V8).tar.gz" "$(PACKAGE_DARWIN_AMD64_V1).tar.gz" "$(PACKAGE_DARWIN_AMD64_V2).tar.gz" "$(PACKAGE_DARWIN_AMD64_V3).tar.gz" "$(PACKAGE_DARWIN_ARM64_V8).tar.gz" > ./SHA256SUMS

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

# Private targets

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
