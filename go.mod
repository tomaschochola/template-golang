module github.com/tomaschochola/template-golang

go 1.26.4

tool (
	golang.org/x/tools/cmd/goimports
	golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow
	golang.org/x/vuln/cmd/govulncheck
)

require (
	golang.org/x/mod v0.36.0 // indirect
	golang.org/x/sync v0.20.0 // indirect
	golang.org/x/sys v0.44.0 // indirect
	golang.org/x/telemetry v0.0.0-20260508192327-42602be52be6 // indirect
	golang.org/x/tools v0.45.0 // indirect
	golang.org/x/vuln v1.3.0 // indirect
)
