## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled Resource Consumption vulnerability in AST parser reading arbitrary files into memory.
**Learning:** Utility scripts that read file contents for parsing must treat those files as untrusted input to prevent DoS attacks via large files.
**Prevention:** Enforce a file size limit (e.g., 1MB using `path.stat().st_size`) before reading files into memory for processing.
