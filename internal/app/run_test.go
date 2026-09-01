package app_test

import (
	"bytes"
	"errors"
	"io"
	"os"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/tomaschochola/template-golang/v2/internal/app"
)

var errFailingWriter = errors.New("write failed")

type failingWriter struct{}

func (failingWriter) Write(_ []byte) (int, error) {
	return 0, errFailingWriter
}

func TestRun(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		arguments []string
		want      string
	}{
		{name: "without arguments"},
		{name: "with arguments", arguments: []string{"first", "second argument", "--third"}, want: "first\nsecond argument\n--third\n"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var output bytes.Buffer

			if err := app.Run(&output, tt.arguments); err != nil {
				t.Fatalf("Run() error = %v, want nil", err)
			}

			if got := output.String(); got != tt.want {
				t.Fatalf("Run() output = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestRunPropagatesWriteError(t *testing.T) {
	t.Parallel()

	err := app.Run(failingWriter{}, []string{"argument"})
	if !errors.Is(err, errFailingWriter) {
		t.Fatalf("Run() error = %v, want %v", err, errFailingWriter)
	}
}

func TestRunRequiresOutputWriter(t *testing.T) {
	t.Parallel()

	if err := app.Run(nil, nil); !errors.Is(err, app.ErrOutputWriterRequired) {
		t.Fatalf("Run() error = %v, want %v", err, app.ErrOutputWriterRequired)
	}
}

func TestRunRejectsInvalidArgumentsBeforeWriting(t *testing.T) {
	t.Parallel()

	fullLine := strings.Repeat("a", app.MaxArgumentBytes-1)
	excessiveOutput := make([]string, app.MaxOutputBytes/app.MaxArgumentBytes+1)
	for index := range excessiveOutput {
		excessiveOutput[index] = fullLine
	}

	tests := []struct {
		name      string
		arguments []string
		want      error
	}{
		{name: "argument too long", arguments: []string{strings.Repeat("a", app.MaxArgumentBytes+1)}, want: app.ErrArgumentTooLong},
		{name: "invalid UTF-8", arguments: []string{"valid", string([]byte{0xff})}, want: app.ErrArgumentInvalidUTF8},
		{name: "output too long", arguments: excessiveOutput, want: app.ErrOutputTooLong},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var output bytes.Buffer

			if err := app.Run(&output, tt.arguments); !errors.Is(err, tt.want) {
				t.Fatalf("Run() error = %v, want %v", err, tt.want)
			}

			if output.Len() != 0 {
				t.Fatalf("Run() output length = %d, want 0", output.Len())
			}
		})
	}
}

func FuzzRun(f *testing.F) {
	f.Add("")
	f.Add("argument")
	f.Add("second argument")
	f.Add("--third")
	f.Add(strings.Repeat("a", app.MaxArgumentBytes+1))
	f.Add(string([]byte{0xff}))

	f.Fuzz(func(t *testing.T, argument string) {
		var output bytes.Buffer

		err := app.Run(&output, []string{argument})

		if len(argument) > app.MaxArgumentBytes {
			if !errors.Is(err, app.ErrArgumentTooLong) {
				t.Fatalf("Run() error = %v, want %v", err, app.ErrArgumentTooLong)
			}

			return
		}

		if !utf8.ValidString(argument) {
			if !errors.Is(err, app.ErrArgumentInvalidUTF8) {
				t.Fatalf("Run() error = %v, want %v", err, app.ErrArgumentInvalidUTF8)
			}

			return
		}

		if err != nil {
			t.Fatalf("Run() error = %v, want nil", err)
		}

		if got, want := output.String(), argument+"\n"; got != want {
			t.Fatalf("Run() output = %q, want %q", got, want)
		}
	})
}

func ExampleRun() {
	if err := app.Run(os.Stdout, []string{"first", "second argument", "--third"}); err != nil {
		panic(err)
	}

	// Output:
	// first
	// second argument
	// --third
}

func BenchmarkRun(b *testing.B) {
	for b.Loop() {
		if err := app.Run(io.Discard, []string{"first", "second argument", "--third"}); err != nil {
			b.Fatal(err)
		}
	}
}
