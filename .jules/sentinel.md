## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-06-09 - Uncontrolled Resource Consumption via File Reading
**Vulnerability:** Uncontrolled Resource Consumption (DoS) risk when reading potentially massive files directly into memory with `f.read()` during AST parsing.
**Learning:** Calling `f.read()` on files without first validating their size can lead to memory exhaustion, especially when processing all files in a directory tree.
**Prevention:** Always implement file size limits (e.g., using `path.stat().st_size`) before loading entire file contents into memory, and route skipping warnings to `sys.stderr` to avoid polluting stdout.
