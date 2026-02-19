# Sentinel Journal - Security Learnings

## 2026-02-19 - [Enhancement] Prevent XSS in Context Generation
**Vulnerability:** The project context generator (`generate_context.py`) instantiated `jinja2.Environment` without enabling `autoescape`. This meant that file names, dependencies, or other project metadata containing Markdown/HTML special characters could be rendered as raw HTML in `Agents.md` or `Readme.md`, potentially leading to Stored XSS if viewed in a vulnerable Markdown viewer.
**Learning:** Even internal tools generating documentation should treat inputs as untrusted, especially when those inputs (file names, dependency versions) can be influenced by attackers or misconfiguration.
**Prevention:** Always enable `autoescape=True` or use `jinja2.select_autoescape(['html', 'xml', 'md'])` when configuring Jinja2 environments, regardless of the output format.
