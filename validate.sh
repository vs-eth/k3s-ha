#!/bin/bash

# Basic validation script for k3s-ha role
# This script checks for basic file structure and syntax

set -e

echo "🔍 Validating k3s-ha Ansible role..."

# Check if we're in the right directory
if [[ ! -f "meta/main.yml" ]]; then
    echo "❌ Error: meta/main.yml not found. Are you in the role directory?"
    exit 1
fi

echo "✅ Role directory structure found"

# Check required directories
required_dirs=("tasks" "handlers" "templates" "vars" "defaults" "meta" "examples")
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "❌ Error: Required directory '$dir' not found"
        exit 1
    fi
done

echo "✅ All required directories present"

# Check required files
required_files=(
    "tasks/main.yml"
    "handlers/main.yml" 
    "templates/config.yaml.j2"
    "templates/k3s.service.j2"
    "defaults/main.yml"
    "meta/main.yml"
    "examples/playbook.yml"
    "examples/inventory.ini"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ Error: Required file '$file' not found"
        exit 1
    fi
done

echo "✅ All required files present"

# Check YAML syntax if ansible-playbook is available
if command -v ansible-playbook &> /dev/null; then
    echo "🔍 Checking YAML syntax..."
    
    # Create temporary test playbook
    cat > /tmp/test-syntax.yml << 'EOF'
---
- hosts: localhost
  connection: local
  gather_facts: true
  vars:
    k3s_token: "test-token-123456789"
    k3s_cluster_init: true
  tasks:
    - name: Include k3s-ha tasks
      include_tasks: tasks/main.yml
EOF
    
    # Check tasks via temporary playbook
    ansible-playbook --syntax-check /tmp/test-syntax.yml 2>/dev/null || {
        echo "❌ Error: Syntax error in tasks/main.yml"
        exit 1
    }
    
    # Check example playbook
    ansible-playbook --syntax-check examples/playbook.yml 2>/dev/null || {
        echo "❌ Error: Syntax error in examples/playbook.yml"  
        exit 1
    }
    
    # Clean up
    rm -f /tmp/test-syntax.yml
    
    echo "✅ YAML syntax validation passed"
else
    echo "⚠️  Warning: ansible-playbook not found, skipping syntax validation"
fi

# Check for common issues in templates
echo "🔍 Checking template syntax..."

# Check for unclosed Jinja2 blocks
if_count=$(grep -c "{% if" templates/*.j2 || echo 0)
endif_count=$(grep -c "{% endif %}" templates/*.j2 || echo 0)
if [[ $if_count != $endif_count ]]; then
    echo "⚠️  Warning: Potential unclosed {% if %} blocks in templates (if: $if_count, endif: $endif_count)"
fi

# Check for undefined variables (basic check)
if grep -n "{{ [^}]*undefined" templates/*.j2; then
    echo "❌ Error: Found 'undefined' in templates"
    exit 1
fi

echo "✅ Template syntax looks good"

# Check README completeness
echo "🔍 Checking documentation..."

if [[ ! -f "README.md" ]]; then
    echo "❌ Error: README.md not found"
    exit 1
fi

# Check if README has basic sections
required_sections=("## Overview" "## Requirements" "## Quick Start" "## Configuration")
for section in "${required_sections[@]}"; do
    if ! grep -q "$section" README.md; then
        echo "⚠️  Warning: README.md missing section: $section"
    fi
done

echo "✅ Documentation structure looks good"

# Summary
echo ""
echo "🎉 Role validation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test the role with a real inventory"
echo "2. Run ansible-lint if available"
echo "3. Test in a development environment"
echo ""
echo "Usage example:"
echo "  ansible-playbook -i examples/inventory.ini examples/playbook.yml"