package main

import (
	"bytes"
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/tomaschochola/template-golang/internal/app"
)

var errFailingWriter = errors.New("write failed")

type failingWriter struct{}

func (failingWriter) Write(_ []byte) (int, error) {
	return 0, errFailingWriter
}

func TestRun(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		args       []string
		version    string
		wantStdout string
		wantErr    bool
		wantErrIs  error
	}{
		{name: "default", wantStdout: app.DefaultMessage + "\n"},
		{name: "custom message", args: []string{"Ahoj"}, wantStdout: "Ahoj\n"},
		{name: "message starting with dash", args: []string{"--", "-Ahoj"}, wantStdout: "-Ahoj\n"},
		{name: "version", args: []string{"--version"}, version: "1.2.3", wantStdout: "template-golang 1.2.3\n"},
		{name: "empty version fallback", args: []string{"--version"}, wantStdout: "template-golang dev\n"},
		{name: "version rejects message", args: []string{"--version", "Ahoj"}, wantErr: true},
		{name: "too many args", args: []string{"one", "two"}, wantErr: true},
		{name: "invalid flag", args: []string{"--unknown"}, wantErr: true},
		{name: "invalid utf8", args: []string{string([]byte{0xff})}, wantErr: true, wantErrIs: app.ErrInvalidMessage},
		{name: "too long", args: []string{strings.Repeat("a", app.MaxMessageBytes+1)}, wantErr: true, wantErrIs: app.ErrMessageTooLong},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var stdout bytes.Buffer
			var stderr bytes.Buffer

			err := run(&stdout, &stderr, tt.args, tt.version)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("run() error = nil, want error")
				}

				if tt.wantErrIs != nil && !errors.Is(err, tt.wantErrIs) {
					t.Fatalf("run() error = %v, want %v", err, tt.wantErrIs)
				}
			} else if err != nil {
				t.Fatalf("run() error = %v, want nil", err)
			}

			if got := stdout.String(); got != tt.wantStdout {
				t.Fatalf("run() stdout = %q, want %q", got, tt.wantStdout)
			}
		})
	}
}

func TestRunHelp(t *testing.T) {
	t.Parallel()

	var stdout bytes.Buffer
	var stderr bytes.Buffer

	if err := run(&stdout, &stderr, []string{"--help"}, "test"); err != nil {
		t.Fatalf("run() error = %v, want nil", err)
	}

	if stdout.Len() != 0 {
		t.Fatalf("run() stdout = %q, want empty", stdout.String())
	}

	if got := stderr.String(); !strings.Contains(got, "Usage of template-golang") {
		t.Fatalf("run() stderr = %q, want usage", got)
	}
}

func TestRunPropagatesWriteError(t *testing.T) {
	t.Parallel()

	err := run(failingWriter{}, io.Discard, []string{"Ahoj"}, "test")
	if !errors.Is(err, errFailingWriter) {
		t.Fatalf("run() error = %v, want %v", err, errFailingWriter)
	}
}
