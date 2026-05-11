## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption in File Parsing
**Vulnerability:** Denial of Service (DoS) risk via memory exhaustion when reading arbitrarily large Python files for AST parsing.
**Learning:** Utility scripts often implicitly trust local files. However, large files or untrusted inputs can crash the process when loaded entirely into memory (e.g., `f.read()`).
**Prevention:** Always implement file size limits (e.g., `path.stat().st_size > 1024 * 1024` for 1MB) before reading contents into memory, especially when performing resource-intensive operations like AST parsing. Treat local file contents as untrusted input in terms of resource consumption.
