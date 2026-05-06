## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption in AST Parsing
**Vulnerability:** Denial of Service (DoS) risk due to reading unbounded file sizes into memory for AST parsing.
**Learning:** Utility scripts that traverse and parse files must treat file contents as untrusted input to prevent Uncontrolled Resource Consumption.
**Prevention:** Enforce a strict file size limit (e.g., 1MB using `path.stat().st_size`) before opening and reading files into memory.
