## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Denial of Service (DoS) due to unconstrained file reading into memory for AST parsing.
**Learning:** Utility scripts often treat local file contents as trusted. However, reading arbitrarily large files into memory (`f.read()`) can crash the process due to memory exhaustion. File contents should be treated as untrusted input.
**Prevention:** Enforce strict file size limits (e.g., 1MB) before reading contents into memory, especially during recursive directory scans.
