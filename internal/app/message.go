package app

import (
	"errors"
	"unicode/utf8"
)

const DefaultMessage = "Hello from Go"
const MaxMessageBytes = 4096

var ErrInvalidMessage = errors.New("message must be valid UTF-8")
var ErrMessageTooLong = errors.New("message is too long")

func Message(input string) (string, error) {
	if input == "" {
		return DefaultMessage, nil
	}

	if len(input) > MaxMessageBytes {
		return "", ErrMessageTooLong
	}

	if !utf8.ValidString(input) {
		return "", ErrInvalidMessage
	}

	return input, nil
}
