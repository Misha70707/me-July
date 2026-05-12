## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled Resource Consumption (DoS) via excessively large files read entirely into memory during AST analysis.
**Learning:** File contents must be treated as untrusted input in utility scripts. Reading unbounded files with `f.read()` can lead to memory exhaustion and DoS.
**Prevention:** Implement file size limits (e.g., using `path.stat().st_size`) before attempting to process or load file contents into memory.
