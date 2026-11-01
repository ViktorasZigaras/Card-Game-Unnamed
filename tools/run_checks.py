#!/usr/bin/env python3
"""Run the Godot import and regression suite using a local Godot 4 executable."""
import argparse
import shutil
import subprocess
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default=shutil.which('godot') or shutil.which('godot4'))
parser.add_argument('--suite', choices=['marketplace', 'commons', 'reservations', 'housing', 'cash'], default='marketplace', help='Marketplace runs the current six-game paired scenario; other suites reproduce historical variants')
args = parser.parse_args()
if not args.godot:
    parser.error('Pass --godot /path/to/Godot executable')
root = Path(__file__).resolve().parents[1]
for flags in [ ['--editor', '--import', '--quit'], ['--script', {'marketplace':'res://tests/marketplace_experiment.gd','commons':'res://tests/commons_experiment.gd','reservations':'res://tests/reservation_experiment.gd','housing':'res://tests/housing_experiment.gd','cash':'res://tests/run_tests.gd'}[args.suite]] ]:
    subprocess.run([args.godot, '--headless', '--path', str(root), *flags], check=True)
