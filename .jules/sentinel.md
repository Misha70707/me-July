## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption in AST Parsing
**Vulnerability:** Uncontrolled Resource Consumption (DoS) when reading large files into memory for AST parsing in `generate_context.py`.
**Learning:** File contents must be treated as untrusted input. Attempting to read arbitrarily large files into memory using `f.read()` before passing them to memory-intensive operations like `ast.parse()` can exhaust system memory.
**Prevention:** Always enforce a file size limit (e.g., 1MB via `py_file.stat().st_size`) before loading files into memory for processing in utility scripts.
