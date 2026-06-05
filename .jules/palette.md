## 2024-05-25 - CLI Error Output
**Learning:** CLI scripts must route error messages to `sys.stderr` to prevent corrupting `stdout` when the output is piped or parsed by other tools, which is a critical UX requirement for CLI applications.
**Action:** Always use `file=sys.stderr` in `print()` statements for warnings and errors in CLI scripts.
