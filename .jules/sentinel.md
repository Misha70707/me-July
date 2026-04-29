## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption in AST Parser
**Vulnerability:** Uncontrolled Resource Consumption (DoS risk) in `generate_context.py` due to reading arbitrarily large Python files into memory for AST parsing.
**Learning:** Utility scripts that process files must treat file contents and sizes as untrusted input. Loading a massive file into memory can crash the process or system.
**Prevention:** Always implement file size limits (e.g., `< 1MB`) before reading file contents into memory, especially for recursive directory scans.
