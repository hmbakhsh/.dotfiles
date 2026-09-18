from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


INSTALLER = Path(__file__).resolve().parents[1] / "install.py"


class InstallerTest(unittest.TestCase):
    def test_install_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            first = subprocess.run([sys.executable, str(INSTALLER), "--home", str(home)], check=False)
            second = subprocess.run(
                [sys.executable, str(INSTALLER), "--home", str(home), "--check"], check=False
            )

            self.assertEqual(first.returncode, 0)
            self.assertEqual(second.returncode, 0)
            self.assertTrue((home / ".agents/skills/personal-skill-install").is_symlink())
            self.assertTrue((home / ".claude/CLAUDE.md").is_symlink())
            self.assertIn(
                "managed-by: personal-agent-skills",
                (home / ".config/opencode/commands/personal-skill-install.md").read_text(),
            )

    def test_unmanaged_collision_is_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            collision = home / ".agents/skills/dev-machine-cleanup"
            collision.mkdir(parents=True)
            marker = collision / "keep.txt"
            marker.write_text("mine")

            result = subprocess.run([sys.executable, str(INSTALLER), "--home", str(home)], check=False)

            self.assertEqual(result.returncode, 1)
            self.assertEqual(marker.read_text(), "mine")


if __name__ == "__main__":
    unittest.main()
