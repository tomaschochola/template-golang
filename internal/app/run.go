package app

import (
	"errors"
	"fmt"
	"io"
	"unicode/utf8"
)

const MaxArgumentBytes = 4096
const MaxOutputBytes = 64 * 1024

var ErrArgumentInvalidUTF8 = errors.New("argument must be valid UTF-8")
var ErrArgumentTooLong = errors.New("argument is too long")
var ErrOutputTooLong = errors.New("output is too long")
var ErrOutputWriterRequired = errors.New("output writer is required")

func Run(output io.Writer, arguments []string) error {
	if output == nil {
		return ErrOutputWriterRequired
	}

	totalBytes := 0

	for _, argument := range arguments {
		if len(argument) > MaxArgumentBytes {
			return ErrArgumentTooLong
		}

		if !utf8.ValidString(argument) {
			return ErrArgumentInvalidUTF8
		}

		lineBytes := len(argument) + 1
		if lineBytes > MaxOutputBytes-totalBytes {
			return ErrOutputTooLong
		}

		totalBytes += lineBytes
	}

	for _, argument := range arguments {
		if _, err := fmt.Fprintln(output, argument); err != nil {
			return err
		}
	}

	return nil
}
