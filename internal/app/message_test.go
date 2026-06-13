package app_test

import (
	"errors"
	"fmt"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/tomaschochola/template-golang/internal/app"
)

func TestMessage(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		in   string
		want string
		err  error
	}{
		{name: "default", want: app.DefaultMessage},
		{name: "custom", in: "Ahoj", want: "Ahoj"},
		{name: "unicode", in: "Žluťoučký kůň", want: "Žluťoučký kůň"},
		{name: "max length", in: strings.Repeat("a", app.MaxMessageBytes), want: strings.Repeat("a", app.MaxMessageBytes)},
		{name: "too long", in: strings.Repeat("a", app.MaxMessageBytes+1), err: app.ErrMessageTooLong},
		{name: "invalid utf8", in: string([]byte{0xff}), err: app.ErrInvalidMessage},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			got, err := app.Message(tt.in)
			if !errors.Is(err, tt.err) {
				t.Fatalf("Message(%q) error = %v, want %v", tt.in, err, tt.err)
			}

			if got != tt.want {
				t.Fatalf("Message(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

func FuzzMessage(f *testing.F) {
	f.Add("")
	f.Add("Ahoj")
	f.Add("Žluťoučký kůň")
	f.Add(strings.Repeat("a", app.MaxMessageBytes))
	f.Add(strings.Repeat("a", app.MaxMessageBytes+1))
	f.Add(string([]byte{0xff}))

	f.Fuzz(func(t *testing.T, input string) {
		got, err := app.Message(input)
		if err != nil {
			if input == "" {
				t.Fatalf("Message(%q) returned error for default input: %v", input, err)
			}

			if len(input) > app.MaxMessageBytes {
				if !errors.Is(err, app.ErrMessageTooLong) {
					t.Fatalf("Message(%q) error = %v, want %v", input, err, app.ErrMessageTooLong)
				}
				return
			}

			if !utf8.ValidString(input) {
				if !errors.Is(err, app.ErrInvalidMessage) {
					t.Fatalf("Message(%q) error = %v, want %v", input, err, app.ErrInvalidMessage)
				}
				return
			}

			t.Fatalf("Message(%q) unexpected error: %v", input, err)
		}

		if got == "" {
			t.Fatalf("Message(%q) returned empty output", input)
		}

		if !utf8.ValidString(got) {
			t.Fatalf("Message(%q) returned invalid UTF-8", input)
		}

		if len(got) > app.MaxMessageBytes {
			t.Fatalf("Message(%q) returned %d bytes, max %d", input, len(got), app.MaxMessageBytes)
		}

		if input == "" {
			if got != app.DefaultMessage {
				t.Fatalf("Message(%q) = %q, want default %q", input, got, app.DefaultMessage)
			}
			return
		}

		if got != input {
			t.Fatalf("Message(%q) = %q, want input unchanged", input, got)
		}
	})
}

func ExampleMessage() {
	message, err := app.Message("Ahoj")
	if err != nil {
		panic(err)
	}

	fmt.Println(message)
	// Output:
	// Ahoj
}

func BenchmarkMessage(b *testing.B) {
	b.ReportAllocs()

	for b.Loop() {
		_, err := app.Message("Ahoj")
		if err != nil {
			b.Fatal(err)
		}
	}
}
