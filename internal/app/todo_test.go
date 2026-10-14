package app_test

import (
	"testing"

	"github.com/tomaschochola/template-golang/v2/internal/app"
)

func TestTodoReturnsZero(t *testing.T) {
	t.Parallel()

	if got := app.Todo(); got != 0 {
		t.Fatalf("Todo() = %d, want 0", got)
	}
}
