## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-06-08 - File Size DoS Prevention
**Vulnerability:** Uncontrolled resource consumption (DoS risk) when reading arbitrary Python files into memory using `f.read()`.
**Learning:** Calling `f.read()` without size limits can crash the application if the file is excessively large. File size checks must be performed prior to reading. When conditionally skipping variable assignments based on this check, the variable must be initialized prior to the condition block to prevent `UnboundLocalError`.
**Prevention:** Always verify file size using `path.stat().st_size` against a reasonable limit (e.g., 1MB) before reading contents into memory.
