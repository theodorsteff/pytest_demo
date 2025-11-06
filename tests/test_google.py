def test_google_title(driver):
    """Open google.com and check the page title contains 'Google'."""
    driver.get("https://www.google.com")
    # Some regions may show localized titles; we assert 'Google' is a substring.
    assert "Google" in driver.title
