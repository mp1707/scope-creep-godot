#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
LOG_DIR="${SCOPE_CREEP_GODOT_LOG_DIR:-/private/tmp}"

checks=(
	"res://scripts/validation/run_content_validation.gd"
	"res://tests/test_essential_core_rules.gd"
)

for check_script in "${checks[@]}"; do
	echo "==> ${check_script}"
	log_name="scope_creep_$(basename "${check_script}" .gd).log"
	"${GODOT_BIN}" --headless --log-file "${LOG_DIR}/${log_name}" --path "${PROJECT_DIR}" --script "${check_script}"
done

echo "PoC checks passed."
