# Makefile

SHELL := /usr/bin/env bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:

# Tooling

GO ?= go
GOFMT ?= gofmt
SUDO ?= sudo
PACMAN ?= pacman
ARCH_PACKAGES ?= base base-devel go git clang graphviz
GOWORK ?= off
GOAMD64 ?= v3

export GOWORK GOAMD64

# Project configuration

MODULE := $(shell $(GO) list -m 2>/dev/null)
PACKAGES ?= ./...
COVER_PACKAGES ?= ./...
COMMAND ?= template-golang
COMMAND_DIR ?= ./cmd/$(COMMAND)
COMMAND_PACKAGE ?= $(COMMAND_DIR)
BINARY ?= ./build/$(COMMAND)

# Verification knobs

TEST_CPU ?= 1,2,4,8
TEST_TIMEOUT ?= 2m
BENCH ?= .
BENCH_TIME ?= 1s
BENCH_COUNT ?= 5
FUZZ_PACKAGE ?= ./internal/app
FUZZ_TARGET ?= FuzzMessage
FUZZ_TIME ?= 10s
PROFILE_PACKAGE ?= ./internal/app
GOVULNCHECK_SHOW ?= version
BUILD_CGO_ENABLED ?= 0
GO_BUILDMODE ?= pie
FIPS_MODE ?= latest
RUN_ARGS ?=
MSAN_CC ?= clang
VERSION ?= dev

# Generated artifacts

COVERAGE_PROFILE ?= coverage.out
COVERAGE_HTML ?= coverage.html
PROFILE_DIR ?= ./build/profiles
INTEGRATION_COVERAGE_DIR ?= ./build/coverage-integration
INTEGRATION_COVERAGE_PROFILE ?= ./build/coverage-integration.out

# Shared official Go flags

GO_LDFLAGS ?= -X main.version=$(VERSION)
GO_BUILD_FLAGS := -mod=readonly -trimpath -buildvcs=true -buildmode=$(GO_BUILDMODE) -pgo=auto -ldflags "$(GO_LDFLAGS)"
GO_TEST_FLAGS := -mod=readonly -v -race -count=2 -shuffle=on -vet=all -cpu=$(TEST_CPU) -timeout=$(TEST_TIMEOUT) -fullpath -covermode=atomic -coverpkg=$(COVER_PACKAGES)

# Default goal

.DEFAULT_GOAL := help

# Goals

.PHONY: help
.SILENT: help
help:
	printf '\033[1m%s\033[0m\n' "$${PWD##*/} targets"
	printf '%s\n' '--------------------------------------------------------------------------------'
	printf '\033[1m%-25s\033[0m  %s\n' 'help' 'Show this help.'
	printf '\033[1m%-25s\033[0m  %s\n' 'arch' 'Install Arch Linux development packages via one sudo pacman call.'
	printf '\033[1m%-25s\033[0m  %s\n' 'archlinux' 'Alias for arch.'
	printf '\033[1m%-25s\033[0m  %s\n' 'pacman' 'Alias for arch.'
	printf '\033[1m%-25s\033[0m  %s\n' 'all' 'Build release artifacts and print build metadata.'
	printf '\033[1m%-25s\033[0m  %s\n' 'fix' 'Run all automatic official Go fixers/formatters.'
	printf '\033[1m%-25s\033[0m  %s\n' 'check' 'Run lint, static analysis, tests, and audits.'
	printf '\033[1m%-25s\033[0m  %s\n' 'deep_check' 'Run all normal and extended verification targets.'
	printf '\033[1m%-25s\033[0m  %s\n' 'lint' 'Run formatting checks.'
	printf '\033[1m%-25s\033[0m  %s\n' 'static' 'Run module, build, modernizer, vet, and analyzer checks.'
	printf '\033[1m%-25s\033[0m  %s\n' 'test' 'Run the race-enabled Go test suite.'
	printf '\033[1m%-25s\033[0m  %s\n' 'coverage' 'Generate Go unit coverage reports.'
	printf '\033[1m%-25s\033[0m  %s\n' 'integration_coverage' 'Generate coverage from an instrumented command binary.'
	printf '\033[1m%-25s\033[0m  %s\n' 'benchmark' 'Run Go benchmarks with allocation reporting.'
	printf '\033[1m%-25s\033[0m  %s\n' 'fuzz' 'Run one bounded Go fuzz target.'
	printf '\033[1m%-25s\033[0m  %s\n' 'profile' 'Generate official Go CPU/memory/block/mutex profiles for one package.'
	printf '\033[1m%-25s\033[0m  %s\n' 'sanitize' 'Run sanitizer checks that are safe by default on this template.'
	printf '\033[1m%-25s\033[0m  %s\n' 'audit' 'Run module verification and govulncheck scans.'
	printf '\033[1m%-25s\033[0m  %s\n' 'clean' 'Remove generated artifacts.'
	printf '\033[1m%-25s\033[0m  %s\n' 'distclean' 'Alias for clean.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_fix' 'Apply official go fix modernizers.'
	printf '\033[1m%-25s\033[0m  %s\n' 'tidy_fix' 'Tidy Go modules.'
	printf '\033[1m%-25s\033[0m  %s\n' 'gofmt_fix' 'Format Go files with gofmt.'
	printf '\033[1m%-25s\033[0m  %s\n' 'goimports_fix' 'Format Go imports with goimports.'
	printf '\033[1m%-25s\033[0m  %s\n' 'tidy_check' 'Check Go module tidiness.'
	printf '\033[1m%-25s\033[0m  %s\n' 'gofmt_check' 'Check Go formatting with gofmt.'
	printf '\033[1m%-25s\033[0m  %s\n' 'goimports_check' 'Check Go imports with goimports.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_list_check' 'Check package loading including tests and dependencies.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_fix_check' 'Check pending official go fix modernizers.'
	printf '\033[1m%-25s\033[0m  %s\n' 'build_check' 'Compile all packages with hardened build flags.'
	printf '\033[1m%-25s\033[0m  %s\n' 'vet_check' 'Run go vet with all default analyzers.'
	printf '\033[1m%-25s\033[0m  %s\n' 'shadow_check' 'Run the Go shadow analyzer in strict mode.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_test' 'Run the Go test suite.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_coverage' 'Generate Go coverage reports.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_module_audit' 'Verify modules and scan module-level vulnerabilities.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_package_audit' 'Scan package-level vulnerabilities.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_source_audit' 'Scan source symbol reachability vulnerabilities.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_binary_audit' 'Scan built binary vulnerabilities.'
	printf '\033[1m%-25s\033[0m  %s\n' 'go_build_metadata' 'Print embedded Go build metadata for the command binary.'
	printf '\033[1m%-25s\033[0m  %s\n' 'asan_check' 'Run tests with the Go address sanitizer integration.'
	printf '\033[1m%-25s\033[0m  %s\n' 'msan_check' 'Run tests with memory sanitizer; requires Clang/LLVM support.'
	printf '\033[1m%-25s\033[0m  %s\n' 'fips_check' 'Run tests with GOFIPS140 enabled.'
	printf '\033[1m%-25s\033[0m  %s\n' 'build' 'Build the command binary.'
	printf '\033[1m%-25s\033[0m  %s\n' 'build_fips' 'Build the command binary with GOFIPS140 enabled.'

.PHONY: arch archlinux pacman
arch archlinux pacman:
	$(SUDO) $(PACMAN) -Syu --needed $(ARCH_PACKAGES)

.PHONY: all
all: build go_build_metadata

.PHONY: fix
fix: go_fix gofmt_fix goimports_fix tidy_fix

.PHONY: check
check: lint static test audit

.PHONY: deep_check
deep_check: check coverage integration_coverage benchmark fuzz profile sanitize msan_check fips_check build_fips

.PHONY: lint
lint: gofmt_check goimports_check

.PHONY: static
static: tidy_check go_list_check go_fix_check build_check vet_check shadow_check

.PHONY: test
test: go_test

.PHONY: coverage
coverage: go_coverage

.PHONY: sanitize
sanitize: asan_check

.PHONY: audit
audit: go_module_audit go_package_audit go_source_audit go_binary_audit

.PHONY: clean
clean:
	rm -rf ./build
	rm -f "$(COVERAGE_HTML)" "$(COVERAGE_PROFILE)"

.PHONY: distclean
distclean: clean

.PHONY: go_fix
go_fix:
	$(GO) fix $(PACKAGES)

.PHONY: tidy_fix
tidy_fix:
	$(GO) mod tidy

.PHONY: gofmt_fix
gofmt_fix:
	$(GOFMT) -e -s -w .

.PHONY: goimports_fix
goimports_fix:
	$(GO) tool goimports -e -local $(MODULE) -w .

.PHONY: tidy_check
tidy_check:
	$(GO) mod tidy -diff

.PHONY: gofmt_check
gofmt_check:
	test -z "$$($(GOFMT) -e -s -l . | tee /dev/stderr)"

.PHONY: goimports_check
goimports_check:
	test -z "$$($(GO) tool goimports -e -local $(MODULE) -l . | tee /dev/stderr)"

.PHONY: go_list_check
go_list_check:
	$(GO) list -mod=readonly -deps -test $(PACKAGES) >/dev/null

.PHONY: go_fix_check
go_fix_check:
	$(GO) fix -diff $(PACKAGES)

.PHONY: build_check
build_check:
	$(GO) build $(GO_BUILD_FLAGS) $(PACKAGES)

.PHONY: vet_check
vet_check:
	$(GO) vet -mod=readonly $(PACKAGES)

.PHONY: shadow_check
shadow_check:
	$(GO) tool shadow -strict $(PACKAGES)

.PHONY: go_test
go_test:
	$(GO) test $(GO_TEST_FLAGS) $(PACKAGES)

.PHONY: go_coverage
go_coverage:
	$(GO) test $(GO_TEST_FLAGS) -coverprofile="$(COVERAGE_PROFILE)" $(PACKAGES)
	$(GO) tool cover -func="$(COVERAGE_PROFILE)"
	$(GO) tool cover -html="$(COVERAGE_PROFILE)" -o "$(COVERAGE_HTML)"

.PHONY: integration_coverage
integration_coverage:
	rm -rf "$(INTEGRATION_COVERAGE_DIR)"
	mkdir -p "$(INTEGRATION_COVERAGE_DIR)"
	CGO_ENABLED=$(BUILD_CGO_ENABLED) $(GO) build $(GO_BUILD_FLAGS) -cover -covermode=atomic -coverpkg=$(COVER_PACKAGES) -o "$(BINARY).cover" $(COMMAND_PACKAGE)
	GOCOVERDIR="$(INTEGRATION_COVERAGE_DIR)" "$(BINARY).cover" $(RUN_ARGS)
	$(GO) tool covdata percent -i="$(INTEGRATION_COVERAGE_DIR)"
	$(GO) tool covdata textfmt -i="$(INTEGRATION_COVERAGE_DIR)" -o "$(INTEGRATION_COVERAGE_PROFILE)"
	$(GO) tool cover -func="$(INTEGRATION_COVERAGE_PROFILE)"

.PHONY: benchmark
benchmark:
	$(GO) test -mod=readonly -run=^$$ -bench=$(BENCH) -benchmem -count=$(BENCH_COUNT) -benchtime=$(BENCH_TIME) $(PACKAGES)

.PHONY: fuzz
fuzz:
	$(GO) test -mod=readonly -run=^$$ -fuzz=$(FUZZ_TARGET) -fuzztime=$(FUZZ_TIME) $(FUZZ_PACKAGE)

.PHONY: profile
profile:
	mkdir -p "$(PROFILE_DIR)"
	$(GO) test -mod=readonly -run=^$$ -bench=$(BENCH) -benchmem -count=1 -benchtime=$(BENCH_TIME) -o "$(PROFILE_DIR)/profile.test" -cpuprofile="$(PROFILE_DIR)/cpu.pprof" -memprofile="$(PROFILE_DIR)/mem.pprof" -blockprofile="$(PROFILE_DIR)/block.pprof" -mutexprofile="$(PROFILE_DIR)/mutex.pprof" $(PROFILE_PACKAGE)

.PHONY: go_module_audit
go_module_audit:
	$(GO) mod verify
	$(GO) tool govulncheck -scan=module -test -show=$(GOVULNCHECK_SHOW) -C $(COMMAND_DIR)

.PHONY: go_package_audit
go_package_audit:
	$(GO) tool govulncheck -scan=package -test -show=$(GOVULNCHECK_SHOW) $(PACKAGES)

.PHONY: go_source_audit
go_source_audit:
	$(GO) tool govulncheck -scan=symbol -test -show=$(GOVULNCHECK_SHOW) $(PACKAGES)

.PHONY: go_binary_audit
go_binary_audit: build go_build_metadata
	$(GO) tool govulncheck -mode=binary -show=$(GOVULNCHECK_SHOW) "$(BINARY)"

.PHONY: go_build_metadata
go_build_metadata: build
	$(GO) version -m -json "$(BINARY)"

.PHONY: asan_check
asan_check:
	CGO_ENABLED=1 $(GO) test -mod=readonly -asan -count=1 -run=. $(PACKAGES)

.PHONY: msan_check
msan_check:
	CGO_ENABLED=1 CC=$(MSAN_CC) $(GO) test -mod=readonly -msan -count=1 -run=. $(PACKAGES)

.PHONY: fips_check
fips_check:
	GOFIPS140=$(FIPS_MODE) $(GO) test -mod=readonly -count=1 -run=. $(PACKAGES)

.PHONY: build
build:
	CGO_ENABLED=$(BUILD_CGO_ENABLED) $(GO) build $(GO_BUILD_FLAGS) -o "$(BINARY)" $(COMMAND_PACKAGE)

.PHONY: build_fips
build_fips:
	GOFIPS140=$(FIPS_MODE) CGO_ENABLED=$(BUILD_CGO_ENABLED) $(GO) build $(GO_BUILD_FLAGS) -o "$(BINARY).fips" $(COMMAND_PACKAGE)
