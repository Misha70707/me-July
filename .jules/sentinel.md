## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.
## 2026-06-05 - [Uncontrolled Resource Consumption in AST Parsing]
**Vulnerability:** The `analyze_python_code` function reads entire files into memory (`f.read()`) and passes them to `ast.parse` without checking file size, risking Uncontrolled Resource Consumption (DoS) via excessively large files.
**Learning:** Functions that process file contents in memory must always validate file size before reading to prevent out-of-memory or high CPU consumption issues.
**Prevention:** Implement file size limit checks using `Path.stat().st_size` before loading file contents into memory, logging explicit warnings when files are skipped.
