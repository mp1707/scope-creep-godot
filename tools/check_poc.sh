#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

checks=(
	"res://scripts/validation/run_content_validation.gd"
	"res://tests/test_phase_3.gd"
	"res://tests/test_phase_4.gd"
	"res://tests/test_phase_5.gd"
	"res://tests/test_phase_6.gd"
	"res://tests/test_phase_7.gd"
	"res://tests/test_phase_8.gd"
	"res://tests/test_phase_9.gd"
	"res://tests/test_phase_10.gd"
)

for check_script in "${checks[@]}"; do
	echo "==> ${check_script}"
	"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --script "${check_script}"
done

echo "PoC checks passed."
