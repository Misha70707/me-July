## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Denial of Service (DoS) due to memory exhaustion when parsing large Python files with `ast.parse()`.
**Learning:** `ast.parse(f.read())` reads the entire file into memory and builds an Abstract Syntax Tree. Without file size limits, a massive file could crash the utility. It is important to treat file contents as untrusted input in utility scripts.
**Prevention:** Implement a file size limit check (e.g., `if st_size > 1MB`) before attempting to read and parse the file contents.
