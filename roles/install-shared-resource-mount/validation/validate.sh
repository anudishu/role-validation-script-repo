#!/usr/bin/env bash
set -euo pipefail
ROLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "${ROLE_DIR}/../.." && pwd)"
export ROLE_DIR
echo "Role directory: ${ROLE_DIR}"
echo "Repo root:      ${ROOT_DIR}"
fail=0
echo "==> YAML sanity check (python + pyyaml required)"
python - <<'PY' || fail=1
import os, sys
try:
    import yaml
except Exception as e:
    print("PyYAML not installed (pip install pyyaml).")
    sys.exit(1)
 
role_dir = os.environ["ROLE_DIR"]
for base, _, files in os.walk(role_dir):
    for f in files:
        if f.endswith((".yml", ".yaml")):
            p = os.path.join(base, f)
            try:
                with open(p, "r", encoding="utf-8") as fh:
                    yaml.safe_load(fh)
            except Exception as e:
                print(f"YAML ERROR: {p}: {e}")
                sys.exit(1)
print("YAML OK")
PY
echo "==> ansible-playbook syntax-check (if installed)"
if command -v ansible-playbook >/dev/null 2>&1; then
  ansible-playbook -i "${ROOT_DIR}/inventories/prod/hosts.ini"     "${ROOT_DIR}/playbooks/site.yml" --syntax-check || fail=1
else
  echo "WARN: ansible-playbook not found; skipping"
fi
if [[ "${fail}" -ne 0 ]]; then
  echo "VALIDATION FAILED"
  exit 1
fi
echo "VALIDATION PASSED"