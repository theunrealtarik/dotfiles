#!/usr/bin/env python3
import argparse
import os
import time
from collections.abc import Callable
from pathlib import Path

import utils
from lib import FAILED_PACKAGES, Command, Manager, Package, Warehouse

TEMP_PATH = Path("/tmp")
UBIN_PATH = Path("/usr/bin")

PARU_BIN = Path("/usr/bin/paru")

CURR_DIR_PATH = Path(__file__).parent
PACMAN_PACKAGES_PATH = CURR_DIR_PATH.joinpath("./packages/pacman")
PARU_PACKAGES_PATH = CURR_DIR_PATH.joinpath("./packages/paru")


if not (PACMAN_PACKAGES_PATH.exists() and PARU_PACKAGES_PATH.exists()):
    utils.error("Packages lists are missing!")
    exit(1)


def install_system_packages():
    Warehouse.from_list(PACMAN_PACKAGES_PATH, Manager.Pacman).install_all()
    Warehouse.from_list(PARU_PACKAGES_PATH, Manager.Paru).install_all()


def setup():
    commands: list[Command] = [
        Command("sudo timedatectl set-timezone Africa/Algiers"),
        Command("sudo systemctl enable sddm.service -f"),
        Command("sudo systemctl start sddm.service -f"),
        Command("sudo systemctl --user enable --now pipewire wireplumber"),
        Command("XDG_MENU_PREFIX=arch- kbuildsycoca6"),
        Command("sudo systemctl start sshd"),
        Command("sudo systemctl enable sshd"),
        Command("eww daemon"),
    ]

    for cmd in commands:
        result = cmd.run()
        if result is not None and result.ok():
            utils.log(f"Success: `{cmd.raw}`")
        else:
            utils.warn(f"Failed to run command `{cmd.raw}`")

    PULSE_REPO_NAME = "pulse"
    PULSE_TEMP_PATH = TEMP_PATH.joinpath(PULSE_REPO_NAME)
    PULSE_UBIN_PATH = UBIN_PATH.joinpath(PULSE_REPO_NAME)
    PULSE_TRGT_UBIN = PULSE_TEMP_PATH.joinpath(f"./target/release/{PULSE_REPO_NAME}")

    utils.log("Setting up `pulse`")
    time.sleep(1)

    if (
        not PULSE_TEMP_PATH.exists()
        or (PULSE_TEMP_PATH.exists() and len(os.listdir(PULSE_TEMP_PATH))) == 0
    ):
        Command(
            bin="git",
            args=[
                "clone",
                f"https://github.com/theunrealtarik/{PULSE_REPO_NAME}",
                str(PULSE_TEMP_PATH),
            ],
        ).run()

    Command('RUSTFLAGS="-Awarnings" cargo build --release').run(
        cwd=PULSE_TEMP_PATH,
        live=True,
    )

    Command(f"sudo cp {PULSE_TRGT_UBIN} {PULSE_UBIN_PATH}").run()
    Command(f"sudo chmod +x {PULSE_UBIN_PATH}").run()


def wrap():
    if len(FAILED_PACKAGES) != 0:
        utils.warn("The following packages did not install successfully:")
        for pkg in FAILED_PACKAGES:
            print(f"\t- {pkg.name}")


class Stage:
    name: str
    reqs: list[Package]
    __dispatch: Callable

    def __init__(
        self,
        name: str,
        dispatch: Callable,
        reqs: list[Package] = [],
    ) -> None:
        self.name = name
        self.reqs = reqs
        self.__dispatch = dispatch

    def dispatch(self):
        print("\n")
        utils.log(f"Dispatching stage: {stage.name}")

        if len(self.reqs) > 0:
            utils.log(f"Requires: {', '.join(pkg.name for pkg in self.reqs)}")
            time.sleep(1)

            for pkg in self.reqs:
                if not pkg.is_installed():
                    utils.warn(f"{pkg} is required for {self.name}")
                    if not pkg.install():
                        utils.error(
                            f"Failed to install a necessary package: {pkg.name}"
                        )

        self.__dispatch()


def testing():
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--testing", action="store_true", help="Run isolated testing function only"
    )

    args = parser.parse_args()

    stages = [
        Stage(
            name="packages",
            dispatch=install_system_packages,
            reqs=[Package("pacman", Manager.Pacman)],
        ),
        Stage(name="setup", dispatch=setup),
        Stage(name="wrap", dispatch=wrap),
    ]

    start = time.perf_counter()

    for stage in stages:
        try:
            stage.dispatch()
        except Exception as e:
            print(e)

    end = time.perf_counter()
    utils.log(f"Computer is ready to compute! ({end - start:.2f})")
