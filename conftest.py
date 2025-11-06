import os
import tempfile
import shutil
import pytest
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from webdriver_manager.firefox import GeckoDriverManager
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile


@pytest.fixture(scope="session")
def driver():
    """Session-scoped Selenium Firefox driver using webdriver-manager.

    Runs headless by default and uses safe args for CI. If you need to
    debug visually, set `options.headless = False`.
    """
    options = Options()
    # Headless mode for CI by default
    options.headless = True
    # Set a reasonable window size for tests that rely on dimensions
    options.add_argument("--width=1200")
    options.add_argument("--height=800")
    # If the system's 'firefox' is a snap wrapper it can be incompatible
    # with geckodriver. Allow overriding the binary via FIREFOX_BINARY or
    # use a local unpacked firefox at ./firefox/firefox if present.
    firefox_bin = os.environ.get("FIREFOX_BINARY")
    if not firefox_bin:
        candidate = os.path.join(os.getcwd(), "firefox", "firefox")
        if os.path.exists(candidate):
            firefox_bin = candidate
    if firefox_bin:
        options.binary_location = firefox_bin

    # Create and pass an explicit temporary Firefox profile. Some
    # system installations (snap-constrained Firefox, restricted /tmp)
    # can fail to create the default profile; creating one explicitly
    # helps diagnose or avoid that class of error.
    profile = FirefoxProfile()
    # Attach profile to options (Selenium 4 uses options.profile)
    options.profile = profile

    # Enable geckodriver logging to a file for easier debugging
    log_path = os.path.join(os.getcwd(), "geckodriver.log")
    service = Service(GeckoDriverManager().install(), log_path=log_path)

    # Create the browser instance
    try:
        driver = webdriver.Firefox(service=service, options=options)
    except Exception:
        # If Firefox fails to start, collect some environment info and
        # re-raise so logs are available for diagnosis.
        environ_debug = {
            "MOZ_HEADLESS": os.environ.get("MOZ_HEADLESS"),
            "PATH": os.environ.get("PATH"),
            "HOME": os.environ.get("HOME"),
        }
        # write a small debug file next to geckodriver.log
        with open(os.path.join(os.getcwd(), "geckodriver.env.log"), "w") as f:
            f.write(str(environ_debug))
        raise
    yield driver
    driver.quit()
