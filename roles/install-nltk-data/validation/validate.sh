#!/bin/bash
# Validation script for install-nltk-data role
# Checks if NLTK is installed and data packages are available

set -euo pipefail

FAILED=0
ROLE_NAME="install-nltk-data"
NLTK_DATA_DIR="${NLTK_DATA_DIR:-/opt/dataiku/nltk_data}"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: NLTK data directory exists
echo "Check 1: NLTK data directory exists..."
if [[ ! -d "${NLTK_DATA_DIR}" ]]; then
    echo "  ❌ ERROR: NLTK data directory not found at ${NLTK_DATA_DIR}"
    FAILED=1
else
    echo "  ✅ PASS: NLTK data directory exists at ${NLTK_DATA_DIR}"
fi

# Check 2: NLTK data directory has correct permissions
echo "Check 2: NLTK data directory has correct permissions..."
NLTK_DIR_PERMS=$(stat -c "%a" "${NLTK_DATA_DIR}" 2>/dev/null || echo "000")
if [[ "${NLTK_DIR_PERMS}" == "755" ]] || [[ "${NLTK_DIR_PERMS}" == "0755" ]]; then
    echo "  ✅ PASS: NLTK data directory has correct permissions (${NLTK_DIR_PERMS})"
else
    echo "  ⚠️  WARNING: NLTK data directory permissions are ${NLTK_DIR_PERMS} (expected 755)"
fi

# Check 3: Python3 is available
echo "Check 3: Python3 is available..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "  ❌ ERROR: python3 command not found"
    FAILED=1
else
    PYTHON3_VER=$(python3 --version 2>&1)
    echo "  ✅ PASS: Python3 is available (${PYTHON3_VER})"
fi

# Check 4: pip3 is available
echo "Check 4: pip3 is available..."
if ! command -v pip3 >/dev/null 2>&1; then
    echo "  ❌ ERROR: pip3 command not found"
    FAILED=1
else
    PIP3_VER=$(pip3 --version 2>&1 | head -1)
    echo "  ✅ PASS: pip3 is available (${PIP3_VER})"
fi

# Check 5: NLTK package is installed
echo "Check 5: NLTK package is installed..."
if ! python3 -c "import nltk" >/dev/null 2>&1; then
    echo "  ❌ ERROR: NLTK package is not installed"
    FAILED=1
else
    NLTK_VER=$(python3 -c "import nltk; print(nltk.__version__)" 2>/dev/null || echo "unknown")
    echo "  ✅ PASS: NLTK package is installed (version: ${NLTK_VER})"
fi

# Check 6: punkt tokenizer data is available
echo "Check 6: punkt tokenizer data is available..."
if python3 << 'PYTHON'
import nltk
import sys
nltk.data.path.append('/opt/dataiku/nltk_data')
try:
    nltk.data.find('tokenizers/punkt')
    print("FOUND")
except LookupError:
    print("NOT_FOUND")
    sys.exit(1)
PYTHON
then
    echo "  ✅ PASS: punkt tokenizer data is available"
else
    echo "  ❌ ERROR: punkt tokenizer data not found"
    FAILED=1
fi

# Check 7: stopwords data is available
echo "Check 7: stopwords data is available..."
if python3 << 'PYTHON'
import nltk
import sys
nltk.data.path.append('/opt/dataiku/nltk_data')
try:
    nltk.data.find('corpora/stopwords')
    print("FOUND")
except LookupError:
    print("NOT_FOUND")
    sys.exit(1)
PYTHON
then
    echo "  ✅ PASS: stopwords data is available"
else
    echo "  ❌ ERROR: stopwords data not found"
    FAILED=1
fi

# Check 8: NLTK can access data from custom directory
echo "Check 8: NLTK can access data from custom directory..."
if python3 << 'PYTHON'
import nltk
import sys
nltk.data.path.append('/opt/dataiku/nltk_data')
if '/opt/dataiku/nltk_data' in nltk.data.path:
    print("ACCESSIBLE")
else:
    print("NOT_ACCESSIBLE")
    sys.exit(1)
PYTHON
then
    echo "  ✅ PASS: NLTK can access data from custom directory"
else
    echo "  ❌ ERROR: NLTK cannot access data from custom directory"
    FAILED=1
fi

# Final result
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ VALIDATION PASSED: All checks passed for ${ROLE_NAME}"
    exit 0
else
    echo "❌ VALIDATION FAILED: One or more checks failed for ${ROLE_NAME}"
    exit 1
fi
