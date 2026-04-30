## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** DoS risk in `generate_context.py` due to unbounded file reads during AST parsing.
**Learning:** Utility scripts that traverse and parse project files must treat file contents as untrusted input, even in local environments, to prevent memory exhaustion from maliciously crafted or accidentally large files.
**Prevention:** Always enforce strict file size limits (e.g., 1MB) before reading file contents into memory or passing them to resource-intensive parsers like `ast`.
