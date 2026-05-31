## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** The script reads the entire content of python files into memory (`f.read()`) regardless of their size, leading to an Uncontrolled Resource Consumption risk (Denial of Service).
**Learning:** Files evaluated solely for existence (`Path.exists()`) don't pose this risk, but any file loaded into memory or processed via AST parsing must have constraints. Treating file contents as untrusted input is essential.
**Prevention:** Implement file size limits (e.g., `path.stat().st_size > 1048576`) before reading arbitrary files into memory or passing them to resource-intensive parsers.
