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

# Goals

.PHONY: fix
fix: go_fix gofmt_fix goimports_fix prettier_fix tidy_fix trimmer_fix

.PHONY: check
check: trimmer_check lint static test audit coverage integration_coverage benchmark fuzz profile asan_check msan_check

.PHONY: lint
lint: gofmt_check goimports_check prettier_check

.PHONY: static
static: tidy_check go_list_check go_fix_check build_check vet_check shadow_check

.PHONY: test
test: go_test

.PHONY: coverage
coverage: go_coverage

.PHONY: audit
audit: npm_audit go_module_audit go_package_audit go_source_audit go_binary_audit

.PHONY: deps_install
deps_install: npm_install

.PHONY: deps_update
deps_update: npm_update

.PHONY: clean
clean:
	rm -rf ./build
	rm -f ./coverage.html ./coverage.out

.PHONY: deps_clean
deps_clean:
	rm -rf ./node_modules

.PHONY: distclean
distclean: clean deps_clean

.PHONY: nuke
nuke: down distclean

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --ignore-scripts -- trimmer check .

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

.PHONY: postcreate
postcreate: deps_install

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: devcontainer
devcontainer: up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: status
status:
	docker container ls --all --filter "$(DEVCONTAINER_FILTER)"

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: restart
restart:
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container restart "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm --volumes "$$container"; done

.PHONY: rebuild
rebuild: devcontainer_check down
	devcontainer up --workspace-folder .

.PHONY: rebuild_no_cache
rebuild_no_cache: devcontainer_check down
	devcontainer up --workspace-folder . --build-no-cache

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
	go test -mod=readonly -v -race -count=2 -shuffle=on -vet=all -cpu=1,2,4,8 -timeout=2m -fullpath -covermode=atomic -coverpkg=./... ./...

.PHONY: go_coverage
go_coverage:
	go test -mod=readonly -v -race -count=2 -shuffle=on -vet=all -cpu=1,2,4,8 -timeout=2m -fullpath -covermode=atomic -coverpkg=./... -coverprofile=./coverage.out ./...
	go tool cover -func=./coverage.out
	go tool cover -html=./coverage.out -o ./coverage.html

.PHONY: integration_coverage
integration_coverage:
	rm -rf ./build/coverage-integration
	mkdir -p ./build/coverage-integration
	CGO_ENABLED=0 go build \
		-mod=readonly \
		-trimpath \
		-buildvcs=true \
		-buildmode=pie \
		-pgo=auto \
		-cover \
		-covermode=atomic \
		-coverpkg=./... \
		-o ./build/template-golang.cover \
		./cmd/template-golang
	GOCOVERDIR=./build/coverage-integration ./build/template-golang.cover
	go tool covdata percent -i=./build/coverage-integration
	go tool covdata textfmt -i=./build/coverage-integration -o ./build/coverage-integration.out
	go tool cover -func=./build/coverage-integration.out

.PHONY: benchmark
benchmark:
	go test -mod=readonly -run=^$$ -bench=. -benchmem -count=5 -benchtime=1s ./...

.PHONY: fuzz
fuzz:
	go test -mod=readonly -run=^$$ -fuzz=FuzzMessage -fuzztime=10s ./internal/app

.PHONY: profile
profile:
	mkdir -p ./build/profiles
	go test \
		-mod=readonly \
		-run=^$$ \
		-bench=. \
		-benchmem \
		-count=1 \
		-benchtime=1s \
		-o ./build/profiles/profile.test \
		-cpuprofile=./build/profiles/cpu.pprof \
		-memprofile=./build/profiles/mem.pprof \
		-blockprofile=./build/profiles/block.pprof \
		-mutexprofile=./build/profiles/mutex.pprof \
		./internal/app

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
go_binary_audit: build
	go tool govulncheck -mode=binary -show=version ./build/template-golang

.PHONY: asan_check
asan_check:
	CGO_ENABLED=1 go test -mod=readonly -asan -count=1 -run=. ./...

.PHONY: msan_check
msan_check:
	CGO_ENABLED=1 CC=clang go test -mod=readonly -msan -count=1 -run=. ./...

.PHONY: build
build:
	CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=true -buildmode=pie -pgo=auto -o ./build/template-golang ./cmd/template-golang

./node_modules/.package-lock.json: ./package.json ./package-lock.json
	$(MAKE) npm_install
