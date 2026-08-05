module github.com/tomaschochola/template-golang/v2

go 1.26.5

tool (
	golang.org/x/tools/cmd/goimports
	golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow
	golang.org/x/vuln/cmd/govulncheck
)

require (
	golang.org/x/mod v0.38.0 // indirect
	golang.org/x/sync v0.22.0 // indirect
	golang.org/x/sys v0.47.0 // indirect
	golang.org/x/telemetry v0.0.0-20260717140457-bdb89881bb75 // indirect
	golang.org/x/tools v0.48.0 // indirect
	golang.org/x/vuln v1.6.0 // indirect
)
