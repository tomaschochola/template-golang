package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/tomaschochola/template-golang/internal/app"
)

const commandName = "template-golang"

func main() {
	if err := run(os.Stdout, os.Stderr, os.Args[1:]); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "%s: %v\n", os.Args[0], err)
		os.Exit(1)
	}
}

func run(stdout io.Writer, stderr io.Writer, args []string) error {
	input, parseErr := parseArgs(stderr, args)
	if parseErr != nil {
		if errors.Is(parseErr, flag.ErrHelp) {
			return nil
		}

		return parseErr
	}

	message, messageErr := app.Message(input)
	if messageErr != nil {
		return messageErr
	}

	_, writeErr := fmt.Fprintln(stdout, message)
	return writeErr
}

func parseArgs(stderr io.Writer, args []string) (string, error) {
	flags := flag.NewFlagSet(commandName, flag.ContinueOnError)
	flags.SetOutput(stderr)

	if err := flags.Parse(args); err != nil {
		return "", err
	}

	rest := flags.Args()
	if len(rest) > 1 {
		return "", fmt.Errorf("expected at most one message argument")
	}

	if len(rest) == 1 {
		return rest[0], nil
	}

	return "", nil
}
