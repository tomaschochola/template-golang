package main

import (
	"fmt"
	"os"

	"github.com/tomaschochola/template-golang/v2/internal/app"
)

func main() {
	if err := app.Run(os.Stdout, os.Args[1:]); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "%s: %v\n", os.Args[0], err)
		os.Exit(1)
	}
}
