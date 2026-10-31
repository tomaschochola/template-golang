package app_test

import (
	"fmt"
	"testing"

	"github.com/tomaschochola/template-golang/internal/app"
)

func TestTodoReturnsZero(t *testing.T) {
	t.Parallel()

	if got := app.Todo(); got != 0 {
		t.Fatalf("Todo() = %d, want 0", got)
	}
}

func FuzzTodo(f *testing.F) {
	f.Add(0)

	f.Fuzz(func(t *testing.T, _ int) {
		if got := app.Todo(); got != 0 {
			t.Fatalf("Todo() = %d, want 0", got)
		}
	})
}

func ExampleTodo() {
	fmt.Println(app.Todo())
	// Output: 0
}

func BenchmarkTodo(b *testing.B) {
	for b.Loop() {
		app.Todo()
	}
}
