## 2025-02-22 - [CLI Safety & Robustness]
**Learning:** CLI tools that auto-generate documentation must not blindly rely on the Current Working Directory (CWD). In a monorepo or nested structure, running a tool from the root can accidentally overwrite critical root-level files (like `README.md` or `Agents.md`) if the tool assumes CWD is the project root.
**Action:** Always anchor file operations to `Path(__file__).parent` to target the specific sub-project the script belongs to, or implement strict checks/confirmations before writing to the repository root.
