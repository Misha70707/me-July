## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2026-02-24 - Uncontrolled Resource Consumption
**Vulnerability:** Utility script `generate_context.py` blindly read files into memory using `f.read()`. A malicious or excessively large file could cause a Denial of Service (DoS) via memory exhaustion.
**Learning:** Even internal utility scripts must treat file contents as untrusted input. `ast.parse` requires the full source code, so a file size check is a necessary pre-validation step.
**Prevention:** Implement file size limits (e.g., `os.stat(f).st_size`) before reading entire files into memory, especially in recursive file processing loops.
