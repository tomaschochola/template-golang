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

export GOWORK := off

# Public goals

.PHONY: all
all: check build coverage benchmark profile

.PHONY: fix
fix: go_fix gofmt_fix goimports_fix tidy_fix prettier_fix trimmer_fix

.PHONY: check
check: trimmer_check lint static test audit fuzz asan_check msan_check

.PHONY: lint
lint: gofmt_check goimports_check prettier_check

.PHONY: static
static: tidy_check go_list_check go_fix_check build_check vet_check shadow_check

.PHONY: test
test: go_test

.PHONY: coverage
coverage: go_coverage

.PHONY: report
report: coverage_serve

.PHONY: audit
audit: npm_audit go_module_audit go_package_audit go_source_audit go_binary_audit

.PHONY: clean
clean:
	rm -rf ./build

.PHONY: distclean
distclean: clean deps_clean

.PHONY: benchmark
benchmark: go_benchmark

.PHONY: fuzz
fuzz: go_fuzz

.PHONY: profile
profile: go_profile

.PHONY: build
build: go_build

.PHONY: postcreate
postcreate: deps_install

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: devcontainer
devcontainer: up
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

.PHONY: deps_install
deps_install: npm_install

.PHONY: deps_update
deps_update: npm_update

.PHONY: deps_clean
deps_clean:
	rm -rf ./node_modules

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- tooling-trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- tooling-trimmer check .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -w .

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -c .

.PHONY: npm_audit
npm_audit: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=high --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_install
npm_install: ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: deps_clean ./package.json
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

.PHONY: go_fix
go_fix:
	go fix ./...

.PHONY: tidy_fix
tidy_fix:
	go mod tidy

.PHONY: gofmt_fix
gofmt_fix:
	gofmt -e -s -w .

.PHONY: goimports_fix
goimports_fix:
	go tool goimports -e -local "$$(go list -m)" -w .

.PHONY: tidy_check
tidy_check:
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

.PHONY: build_check
build_check:
	go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -pgo=auto ./...

.PHONY: vet_check
vet_check:
	go vet -mod=readonly ./...

.PHONY: shadow_check
shadow_check:
	go tool shadow -strict ./...

.PHONY: go_test
go_test:
	go test -mod=readonly -v -race -count=2 -shuffle=on -vet=all -cpu=1,2,4,8 -timeout=2m -fullpath ./...

.PHONY: go_coverage
go_coverage:
	rm -rf ./build/coverage
	mkdir -p ./build/coverage/html
	go test -mod=readonly -v -count=1 -vet=all -timeout=2m -fullpath -covermode=atomic -coverpkg=./... -coverprofile=./build/coverage/coverage.out ./...
	go tool cover -func=./build/coverage/coverage.out
	go tool cover -html=./build/coverage/coverage.out -o ./build/coverage/html/index.html

.PHONY: coverage_serve
coverage_serve: go_coverage
	node --eval 'const fs = require("node:fs"); const http = require("node:http"); http.createServer((_request, response) => { response.setHeader("Content-Type", "text/html; charset=utf-8"); fs.createReadStream("./build/coverage/html/index.html").pipe(response); }).listen(61031, "0.0.0.0", () => console.log("Coverage report: http://localhost:61031"));'

.PHONY: go_benchmark
go_benchmark:
	go test -mod=readonly -run=^$$ -bench=. -benchmem -count=5 -benchtime=1s ./...

.PHONY: go_fuzz
go_fuzz:
	go test -mod=readonly -run=^$$ -fuzz=FuzzMessage -fuzztime=10s ./internal/app

.PHONY: go_profile
go_profile:
	mkdir -p ./build/profiles
	go test -mod=readonly -run=^$$ -bench=. -benchmem -count=1 -benchtime=1s -o ./build/profiles/profile.test -cpuprofile=./build/profiles/cpu.pprof -memprofile=./build/profiles/mem.pprof -blockprofile=./build/profiles/block.pprof -mutexprofile=./build/profiles/mutex.pprof ./internal/app

.PHONY: go_module_audit
go_module_audit:
	go mod verify
	go tool govulncheck -scan=module -test -show=version -C ./cmd/template-golang

.PHONY: go_package_audit
go_package_audit:
	go tool govulncheck -scan=package -test -show=version ./...

.PHONY: go_source_audit
go_source_audit:
	go tool govulncheck -scan=symbol -test -show=version ./...

.PHONY: go_binary_audit
go_binary_audit: go_build
	go tool govulncheck -mode=binary -show=version ./build/template-golang

.PHONY: asan_check
asan_check:
	CGO_ENABLED=1 go test -mod=readonly -asan -count=1 -run=. ./...

.PHONY: msan_check
msan_check:
	CGO_ENABLED=1 CC=clang go test -mod=readonly -msan -count=1 -run=. ./...

.PHONY: go_build
go_build:
	mkdir -p ./build
	CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -pgo=auto -o ./build/template-golang ./cmd/template-golang

# Private targets

./node_modules/.package-lock.json: ./package.json ./package-lock.json
	$(MAKE) npm_install
