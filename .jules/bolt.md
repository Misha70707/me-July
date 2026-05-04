## 2024-05-24 - Handle symlinks and permissions when replacing os.walk
**Learning:** When replacing `os.walk` (which ignores symlinks) with recursive `os.scandir` to optimize tree pruning, explicitly use `entry.is_dir(follow_symlinks=False)` and `entry.is_file(follow_symlinks=False)` to prevent infinite recursion via directory symlinks. Catch `OSError` rather than just `PermissionError` to handle various filesystem access issues.
**Action:** Always explicitly disable symlink following in `os.scandir` when replacing `os.walk` and use broad exception handling (`OSError`) for file system access to maintain robustness.

## 2024-05-24 - Optimize directory traversal with os.walk pruning
**Learning:** `Path.rglob` is inefficient for directory traversal when specific large directories (like `venv/`) need to be excluded, as it traverses the entire tree and filters paths post-generation. Replacing it with `os.walk` and mutating the `dirs` list in-place (`dirs[:] = ...`) using an `IGNORE_DIRS` constant prunes the traversal early, preventing recursion into massive subdirectories and yielding significant performance improvements (~72%).
**Action:** When searching for files in a project, prefer `os.walk` with in-place directory pruning over `Path.rglob` if large dependency or cache directories need to be excluded.
