## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Utility scripts reading large files into memory without bounds checking can lead to memory exhaustion and DoS.
**Learning:** `generate_context.py` read all files matched by `*.py` entirely into memory using `f.read()` and parsed them with `ast.parse()`. Processing massive files (e.g., generated artifacts or obfuscated code) would consume unbounded resources.
**Prevention:** Always check `file.stat().st_size` against a sane limit (e.g., 1MB) before reading untrusted or dynamically discovered file contents into memory, especially when passing data to resource-intensive functions like AST parsers.
