## 2024-06-08 - Uncontrolled Resource Consumption (DoS) via AST Parsing
**Vulnerability:** The script parsed arbitrarily large files using `ast.parse(f.read())` without validating file sizes first, leading to potential Uncontrolled Resource Consumption (DoS) if run against massive or malicious files.
**Learning:** Python CLI tools that process arbitrary files must implement file size limits (using `Path.stat().st_size` for cohesiveness) prior to loading contents into memory. Limits are only needed before reading content, not for mere existence checks.
**Prevention:** Implement an explicit file size check (e.g., `> 1024 * 1024` for 1MB) and route warnings to `sys.stderr` to avoid corrupting `stdout` output expected by chained tools.
