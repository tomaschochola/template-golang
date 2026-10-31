//go:build integration

package app_test

import (
	"io"
	"net/http"
	"net/url"
	"os"
	"testing"
	"time"
)

func TestIntegrationWireMockHealth(t *testing.T) {
	t.Parallel()

	baseURL := os.Getenv("WIREMOCK_URL")

	if baseURL == "" {
		t.Fatal("WIREMOCK_URL must be set for integration tests")
	}

	client := &http.Client{Timeout: 5 * time.Second}

	for _, path := range []string{"/livez", "/readyz"} {
		t.Run(path, func(t *testing.T) {
			t.Parallel()

			endpoint, err := url.JoinPath(baseURL, path)

			if err != nil {
				t.Fatal(err)
			}

			request, err := http.NewRequestWithContext(t.Context(), http.MethodGet, endpoint, nil)

			if err != nil {
				t.Fatal(err)
			}

			response, err := client.Do(request)

			if err != nil {
				t.Fatal(err)
			}

			defer response.Body.Close()

			if response.StatusCode != http.StatusOK {
				t.Errorf("status = %d, want %d", response.StatusCode, http.StatusOK)
			}

			if got := response.Header.Get("Content-Type"); got != "text/plain" {
				t.Errorf("Content-Type = %q, want text/plain", got)
			}

			if got := response.Header.Get("Cache-Control"); got != "no-store" {
				t.Errorf("Cache-Control = %q, want no-store", got)
			}

			body, err := io.ReadAll(io.LimitReader(response.Body, 1024))

			if err != nil {
				t.Fatal(err)
			}

			if string(body) != "ok\n" {
				t.Errorf("body = %q, want %q", body, "ok\n")
			}
		})
	}
}
