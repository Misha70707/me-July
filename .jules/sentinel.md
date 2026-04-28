## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption in Context Generator
**Vulnerability:** The script reads entire Python files into memory for AST parsing without checking file sizes, risking a DoS attack via resource exhaustion if run against a repository containing extremely large generated/malicious `.py` files.
**Learning:** Utility scripts that perform static analysis often assume typical source code files are small, but they must still validate inputs (like file sizes) before loading them fully into memory to maintain resilience.
**Prevention:** Enforce a strict file size limit (e.g., 1MB) using `py_file.stat().st_size` before opening and reading file contents into memory for parsing.
