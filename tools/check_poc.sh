#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
LOG_DIR="${SCOPE_CREEP_GODOT_LOG_DIR:-/private/tmp}"

checks=(
	"res://scripts/validation/run_content_validation.gd"
	"res://tests/test_poc3_phase_1_software_status.gd"
	"res://tests/test_poc3_phase_2_feature_integration.gd"
	"res://tests/test_poc3_phase_3_freelance.gd"
	"res://tests/test_poc3_phase_4_launch.gd"
	"res://tests/test_poc3_phase_5_customer_income.gd"
	"res://tests/test_poc3_phase_6_customer_pressure.gd"
	"res://tests/test_poc3_phase_7_business_goals.gd"
	"res://tests/test_poc3_phase_8_shop_scope.gd"
	"res://tests/test_poc3_phase_9_save_validation.gd"
	"res://tests/test_poc3_phase_10_balance_qa.gd"
	"res://tests/test_poc3_feinschliff.gd"
)

for check_script in "${checks[@]}"; do
	echo "==> ${check_script}"
	log_name="scope_creep_$(basename "${check_script}" .gd).log"
	"${GODOT_BIN}" --headless --log-file "${LOG_DIR}/${log_name}" --path "${PROJECT_DIR}" --script "${check_script}"
done

echo "PoC checks passed."
