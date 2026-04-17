## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.
## 2024-05-23 - Uncontrolled Resource Consumption (DoS)
**Vulnerability:** The script `generate_context.py` reads file contents into memory without enforcing a size limit, leading to Uncontrolled Resource Consumption. An attacker could place an excessively large Python file in the directory tree, causing the script to consume all available memory and crash (DoS).
**Learning:** Utility scripts that traverse file systems and read file contents are susceptible to resource exhaustion if file sizes are not bounded. It's a critical error to treat local file sizes as inherently safe or trusted.
**Prevention:** Always enforce strict file size limits (`st_size` check via `os.stat` or `pathlib.Path.stat`) before attempting to read files into memory or passing them to parsers (like AST), especially in automated scanning or generation scripts.
