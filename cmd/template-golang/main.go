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

var version = "dev"

func main() {
	if err := run(os.Stdout, os.Stderr, os.Args[1:], version); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "%s: %v\n", os.Args[0], err)
		os.Exit(1)
	}
}

type config struct {
	message     string
	showVersion bool
}

func run(stdout io.Writer, stderr io.Writer, args []string, buildVersion string) error {
	cfg, parseErr := parseArgs(stderr, args)
	if parseErr != nil {
		if errors.Is(parseErr, flag.ErrHelp) {
			return nil
		}

		return parseErr
	}

	if cfg.showVersion {
		_, writeErr := fmt.Fprintln(stdout, versionLine(buildVersion))
		return writeErr
	}

	message, messageErr := app.Message(cfg.message)
	if messageErr != nil {
		return messageErr
	}

	_, writeErr := fmt.Fprintln(stdout, message)
	return writeErr
}

func parseArgs(stderr io.Writer, args []string) (config, error) {
	flags := flag.NewFlagSet(commandName, flag.ContinueOnError)
	flags.SetOutput(stderr)

	showVersion := flags.Bool("version", false, "print version")

	if err := flags.Parse(args); err != nil {
		return config{}, err
	}

	rest := flags.Args()
	if *showVersion && len(rest) != 0 {
		return config{}, fmt.Errorf("--version does not accept a message argument")
	}

	if len(rest) > 1 {
		return config{}, fmt.Errorf("expected at most one message argument")
	}

	cfg := config{showVersion: *showVersion}
	if len(rest) == 1 {
		cfg.message = rest[0]
	}

	return cfg, nil
}

func versionLine(buildVersion string) string {
	if buildVersion == "" {
		buildVersion = "dev"
	}

	return commandName + " " + buildVersion
}
