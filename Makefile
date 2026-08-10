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

.PHONY: fix
fix: go_fix gofmt_fix goimports_fix go_mod_fix prettier_fix trimmer_fix

.PHONY: check
check: doctor lint analyze test fuzz audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor

.PHONY: lint
lint: gofmt_check goimports_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check go_mod_check go_list_check go_fix_check go_build_check go_vet_check shadow_check

.PHONY: test
test: go_test asan_check msan_check

.PHONY: coverage
coverage: go_coverage

.PHONY: audit
audit: npm_audit go_audit

.PHONY: update
update: npm_config_check ./package.json ./package-lock.json ./go.mod ./go.sum npm_update go_mod_update

.PHONY: clean
clean:
	rm -rf ./build

.PHONY: distclean
distclean: clean deps_clean

.PHONY: build
build: go_build

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

.PHONY: deps_install
deps_install: npm_install

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
	npm audit --ignore-scripts --audit-level=high --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_clean
npm_clean:
	rm -rf ./node_modules

.PHONY: go_mod_update
go_mod_update: ./go.mod ./go.sum
	go get -u all
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

.PHONY: go_build_check
go_build_check:
	go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -pgo=auto ./...

.PHONY: go_vet_check
go_vet_check:
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

.PHONY: go_audit
go_audit: go_build
	go mod verify
	go tool govulncheck -scan=module -test -show=version -C ./cmd/template-golang
	go tool govulncheck -scan=package -test -show=version ./...
	go tool govulncheck -scan=symbol -test -show=version ./...
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

.PHONY: coverage_serve
coverage_serve: go_coverage
	node --eval 'const fs = require("node:fs"); const http = require("node:http"); http.createServer((_request, response) => { response.setHeader("Content-Type", "text/html; charset=utf-8"); fs.createReadStream("./build/coverage/html/index.html").pipe(response); }).listen(61031, "0.0.0.0", () => console.log("Coverage report: http://localhost:61031"));'

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
