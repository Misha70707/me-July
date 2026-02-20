import sys
from pathlib import Path
from unittest.mock import patch
import pytest

# Add the parent directory to sys.path to import the module
sys.path.append(str(Path(__file__).resolve().parent.parent))

from generate_context import main, find_project_root

def test_find_project_root():
    """Test that find_project_root returns a Path object."""
    root = find_project_root()
    assert isinstance(root, Path)
    assert root.exists()

@patch('generate_context.print')
def test_main_execution(mock_print, tmp_path):
    """Test that main runs without error and generates files."""
    # Mock find_project_root to return the temporary directory
    with patch('generate_context.find_project_root', return_value=tmp_path):
        main()

    # Check if output files were created
    assert (tmp_path / "Agents_generated.md").exists()
    assert (tmp_path / "Readme_generated.md").exists()

    # Verify that the UX improvements (print statements) were executed
    # We check if any print call contained the emoji or color codes we added
    found_ux_elements = False
    for call in mock_print.call_args_list:
        args, _ = call
        if args and ("✨" in args[0] or "🔍" in args[0]):
            found_ux_elements = True
            break

    assert found_ux_elements, "UX improvements (emojis) not found in output"
