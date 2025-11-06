.PHONY: help firefox test test-headless clean

help:  ## Show this help (default target)
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

firefox:  ## Download portable Firefox (if needed) or use existing
	./scripts/get_firefox.sh --keep

firefox-update:  ## Force re-download Firefox (replaces existing)
	./scripts/get_firefox.sh --force

test: firefox  ## Run tests (requires display or run under xvfb-run)
	FIREFOX_BINARY="$$(pwd)/firefox/firefox" pytest -v

test-headless: firefox  ## Run tests headless (no display needed)
	FIREFOX_BINARY="$$(pwd)/firefox/firefox" xvfb-run -s "-screen 0 1920x1080x24" pytest -v

clean:  ## Remove downloaded Firefox and test artifacts
	rm -rf firefox/ .pytest_cache/ __pycache__/ tests/__pycache__/ geckodriver.log geckodriver.env.log