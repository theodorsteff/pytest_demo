Pytest + Selenium demo

This small demo shows how to use pytest with Selenium (Firefox) to open https://www.google.com and verify the page title.

Requirements
- Python 3.8+
- Firefox browser (either system Firefox, or download portable Firefox - see below)
- xvfb package if running headless tests without a display server

Quick start

1) Create a virtual environment and activate it

```bash
python -m venv .venv
source .venv/bin/activate
```

2) Install dependencies

```bash
pip install -r requirements.txt

# On some systems you may need xvfb to run headless:
sudo apt install -y xvfb
```

3) Get Firefox

If your system's Firefox is a snap package or otherwise incompatible, you can use a portable Firefox:

```bash
# Download and unpack Firefox to ./firefox/firefox:
wget -O firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
tar xf firefox.tar.bz2
rm firefox.tar.bz2

# Tell Selenium to use the local Firefox:
export FIREFOX_BINARY="$(pwd)/firefox/firefox"
```

Automatic download

You can use the included helper script to download and unpack Firefox automatically into `./firefox`:

```bash
# Download (or update) the portable Firefox into ./firefox
./scripts/get_firefox.sh

# Then run tests using the downloaded binary:
export FIREFOX_BINARY="$(pwd)/firefox/firefox"
xvfb-run -s "-screen 0 1920x1080x24" pytest -q
```

4) Run tests

```bash
# Run tests (assumes working display):
pytest -q

# Or run tests headless under xvfb:
xvfb-run -s "-screen 0 1920x1080x24" pytest -q
```

5) Complete command would look like this

```bash
# Run tests headless under xvfb:
FIREFOX_BINARY="$(pwd)/firefox/firefox" xvfb-run -s "-screen 0 1920x1080x24" /home/thesteff/workspace/pytest_demo/.venv/bin/python -m pytest -q
```

Notes and troubleshooting
- The project uses `webdriver-manager` to download a matching geckodriver automatically.
- If Firefox fails to start:
  - Try a portable Firefox (see above "Get Firefox" steps).
  - Or install Firefox ESR if available: `sudo apt install -y firefox-esr`
  - If using system Firefox and it's a snap package, you may need to set `FIREFOX_BINARY` to point to a non-snap Firefox binary.
- To run non-headless (debug), edit `conftest.py` and set `options.headless = False`.
