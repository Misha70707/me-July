## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2025-02-23 - Uncontrolled Resource Consumption (DoS)
**Vulnerability:** The `generate_context.py` script read entire file contents into memory via `f.read()` during AST analysis and dependency parsing, making it vulnerable to Denial of Service (DoS) via large files or "zip bombs".
**Learning:** Utility scripts that process user-controlled repositories must treat file contents as untrusted input. Assuming files are small text files is a dangerous assumption.
**Prevention:** Always implement explicit size limits (e.g., checks against `os.stat().st_size`) before reading files into memory, especially in automated analysis tools.
