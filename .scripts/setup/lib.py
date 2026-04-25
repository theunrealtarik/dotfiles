import shlex
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from shutil import ExecError
from typing import List, Optional

import utils

FAILED_PACKAGES: list["Package"] = []


HYPRLAND_PLUGINS = ["https://github.com/zjeffer/split-monitor-workspaces"]


class Manager(Enum):
    Pacman = "pacman"
    Paru = "paru"


# package
@dataclass
class Package:
    name: str
    manager: Manager

    def __repr__(self) -> str:
        return self.name

    def is_installed(self):
        result = subprocess.run(
            f"pacman -Q {self.name}", shell=True, capture_output=True
        )
        return result.returncode == 0

    def install(self, manager: Optional[Manager] = None) -> bool:
        manager = manager if manager is not None else self.manager
        prefix = "sudo" if manager == Manager.Pacman else ""
        cmd = " ".join([prefix, f"{manager.value} -S --needed --noconfirm {self.name}"])

        utils.log(f"Installing {self.name} via {manager.value}...")

        result = subprocess.run(cmd, shell=True)
        if result.returncode == 0:
            return True
        else:
            utils.warn(f"Failed to install {self.name}")
            return False


@dataclass
class Warehouse:
    manager: Manager
    packages: list[Package]

    @classmethod
    def from_list(cls, path: Path, manager: Manager) -> "Warehouse":
        packages: list[Package] = []

        with open(path, "r") as content:
            for name in content.read().split("\n"):
                packages.append(Package(name, manager))

        return cls(manager, packages)

    def install_all(self):
        for pkg in self.packages:
            if pkg.is_installed():
                utils.log(f"{pkg.name} is already installed")
            elif not pkg.install(self.manager):
                FAILED_PACKAGES.append(pkg)


@dataclass
class CommandResult:
    stdout: Optional[str]
    stderr: Optional[str]
    returncode: int
    error: Optional[str] = None

    def ok(self) -> bool:
        return self.returncode == 0 and self.error is None


class Command:
    def __init__(
        self,
        raw: Optional[str] = None,
        *,
        sudo: bool = False,
        bin: Optional[str] = None,
        args: Optional[List[str]] = None,
    ):
        if raw is not None:
            parts = shlex.split(raw)

            if not parts:
                raise ValueError("Empty command")

            if parts[0] == "sudo":
                self.sudo = True
                parts = parts[1:]
            else:
                self.sudo = False

            if not parts:
                raise ValueError("Missing command after sudo")

            self.bin = parts[0]
            self.args = parts[1:]
            self.raw = raw
            return

        if bin is None:
            raise ValueError("`bin` is required when not using raw input")

        self.sudo = sudo
        self.bin = bin
        self.args = args or []

        self.raw = self._build_raw()

    def _build_raw(self) -> str:
        parts = []
        if self.sudo:
            parts.append("sudo")

        parts.append(self.bin)
        parts.extend(self.args)

        return " ".join(shlex.quote(p) for p in parts)

    def to_list(self) -> list[str]:
        cmd = [self.bin, *self.args]
        if self.sudo:
            cmd = ["sudo", *cmd]
        return cmd

    def pipe(self, cmd: "Command") -> CommandResult:
        try:
            p1 = subprocess.Popen(self.to_list(), stdout=subprocess.PIPE)
            p2 = subprocess.Popen(
                cmd.to_list(),
                stdin=p1.stdout,
                stdout=subprocess.PIPE,
            )

            output = p2.communicate()[0]
            if p1.wait() != 0 or p2.wait() != 0:
                return CommandResult(
                    None,
                    None,
                    1,
                    error=f"failed to pipe {self} to {cmd}",
                )
            else:
                return CommandResult(
                    stderr=None,
                    stdout=output.decode("utf-8"),
                    returncode=0,
                    error=None,
                )
        except Exception as e:
            return CommandResult(None, None, 1, error=str(e))

    def run(self, cwd: Optional[Path] = None, live: bool = False, check: bool = False):
        try:
            if not live:
                p = subprocess.run(
                    self.to_list(),
                    capture_output=True,
                    text=True,
                    check=check,
                    cwd=cwd,
                )

                return CommandResult(
                    stdout=p.stdout,
                    stderr=p.stderr,
                    returncode=p.returncode,
                )

            process = subprocess.Popen(
                self.to_list(),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=cwd,
            )

            stdout_lines = []
            stderr_lines = []

            stdout = process.stdout
            stderr = process.stderr

            if stdout is not None:
                for line in stdout:
                    print(line, end="")
                    stdout_lines.append(line)

            if stderr is not None:
                for line in stderr:
                    print(line, end="", file=sys.stderr)
                    stderr_lines.append(line)

            process.wait()

        except FileNotFoundError as e:
            return CommandResult(None, None, 127, error=f"Command not found: {e}")
        except Exception as e:
            return CommandResult(None, None, 1, error=str(e))
