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

.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Run an explicit target' >&2
	exit 1

# Goals

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

.PHONY: nuke
nuke: distclean

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
	out=$$($(GOFMT) -e -s -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

.PHONY: goimports_check
goimports_check:
	out=$$($(GO) tool goimports -e -local $(MODULE) -l .); if [ -n "$$out" ]; then printf '%s\n' "$$out" >&2; exit 1; fi

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
