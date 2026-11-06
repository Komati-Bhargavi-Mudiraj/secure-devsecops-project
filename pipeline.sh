#!/bin/bash

# ==========================================
# SECURE DEVSECOPS PIPELINE
# MCA BEGINNER PROJECT
# ==========================================

PROJECT_DIR="$(pwd)"
IMAGE_NAME="secure-devsecops-app:latest"

# Security report variables
WARNINGS=0
FAILURES=0

declare -a STEP_NAMES=()
declare -a STEP_STATUS=()

# ==========================================
# FUNCTION: RECORD RESULTS
# ==========================================

record() {
    STEP_NAMES+=("$1")
    STEP_STATUS+=("$2")

    if [ "$2" = "FAIL" ]; then
        ((FAILURES++))
    fi
}

# ==========================================
# PIPELINE START
# ==========================================

echo "=========================================="
echo " SECURE DEVSECOPS PIPELINE STARTED"
echo "=========================================="

# ==========================================
# STEP 1: PYTHON ENVIRONMENT
# ==========================================

echo ""
echo "STEP 1: PYTHON ENVIRONMENT"

if command -v python3 >/dev/null 2>&1; then
    python3 --version
    record "Python Environment" "PASS"
else
    echo "Python3 not found."
    record "Python Environment" "FAIL"
fi

# ==========================================
# STEP 2: SECURITY TOOLS
# ==========================================

echo ""
echo "STEP 2: SECURITY TOOLS"

if command -v bandit >/dev/null 2>&1 && \
   command -v pip-audit >/dev/null 2>&1 && \
   docker info >/dev/null 2>&1; then

    echo "Bandit available."
    echo "pip-audit available."
    echo "Docker is running."
    record "Security Tools" "PASS"
else
    echo "One or more security tools are unavailable."
    record "Security Tools" "FAIL"
fi

# ==========================================
# STEP 3: APPLICATION TESTING
# ==========================================

echo ""
echo "STEP 3: APPLICATION TESTING"

if python -m unittest test_app -v; then
    echo "APPLICATION TESTING PASSED"
    record "Application Testing" "PASS"
else
    echo "APPLICATION TESTING FAILED"
    record "Application Testing" "FAIL"
fi

# ==========================================
# STEP 4: BANDIT SECURITY SCAN
# ==========================================

echo ""
echo "STEP 4: BANDIT SECURITY SCAN"

if bandit -r app.py -f txt; then
    echo "BANDIT SCAN COMPLETED"
    record "Bandit Scan" "PASS"
else
    echo "BANDIT SCAN FAILED"
    record "Bandit Scan" "FAIL"
fi

# ==========================================
# STEP 5: DEPENDENCY SCAN
# ==========================================

echo ""
echo "STEP 5: DEPENDENCY VULNERABILITY SCAN"

if pip-audit -r requirements.txt; then
    echo "DEPENDENCY SCAN PASSED"
    record "Dependency Scan" "PASS"
else
    echo "DEPENDENCY SCAN FAILED"
    record "Dependency Scan" "FAIL"
fi

# ==========================================
# STEP 6: GITLEAKS SECRET DETECTION
# ==========================================

echo ""
echo "STEP 6: GITLEAKS SECRET DETECTION"

if docker run --rm \
    -v "$PROJECT_DIR:/path" \
    zricethezav/gitleaks:latest \
    git /path --no-banner; 
then

    echo "No secrets detected."
    record "Gitleaks Scan" "PASS"
else
    echo "Gitleaks scan failed or secrets detected."
    record "Gitleaks Scan" "FAIL"
fi

# ==========================================
# STEP 7: DOCKER IMAGE BUILD
# ==========================================

echo ""
echo "STEP 7: DOCKER IMAGE BUILD"

if docker build -t "$IMAGE_NAME" .; then
    echo "DOCKER IMAGE BUILD PASSED"
    record "Docker Image Build" "PASS"
else
    echo "DOCKER IMAGE BUILD FAILED"
    record "Docker Image Build" "FAIL"
fi

# ==========================================
# STEP 8: TRIVY CONTAINER SCAN
# ==========================================

echo ""
echo "STEP 8: TRIVY CONTAINER SCAN"

if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then

    if docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest \
        image --severity HIGH,CRITICAL "$IMAGE_NAME"; then

        echo "TRIVY SCAN COMPLETED"
        record "Trivy Container Scan" "SCANNED"
    else
        echo "TRIVY SCAN EXECUTION FAILED"
        record "Trivy Container Scan" "FAIL"
    fi

else
    echo "Docker image not available."
    record "Trivy Container Scan" "FAIL"
fi

# ==========================================
# STEP 9: FINAL SECURITY REPORT
# ==========================================

echo ""
echo "STEP 9: FINAL SECURITY REPORT"

echo "=========================================="
echo " SECURE DEVSECOPS PIPELINE SUMMARY"
echo "=========================================="

for i in "${!STEP_NAMES[@]}"; do
    printf "STEP %-2s : %-27s %s\n" \
        "$((i+1))" "${STEP_NAMES[$i]}" "${STEP_STATUS[$i]}"
done

echo "=========================================="

echo "Security warnings : $WARNINGS"
echo "Execution failures: $FAILURES"

if [ "$FAILURES" -eq 0 ]; then
    echo "PIPELINE EXECUTION COMPLETED"
else
    echo "PIPELINE COMPLETED WITH FAILURES"
fi

echo "=========================================="
