## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled Resource Consumption (DoS) risk due to unbounded file reading into memory.
**Learning:** Treating file contents as untrusted input is necessary. Reading untrusted files directly into memory can lead to out-of-memory errors.
**Prevention:** Mitigate by enforcing a 1MB file size limit (`path.stat().st_size > 1048576`) before reading files into memory.
