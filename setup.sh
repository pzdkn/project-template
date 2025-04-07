#!/bin/bash

echo "=== 🐍 Python Project Setup with Poetry ==="

########################################
# 0. Check for existing pyproject.toml #
########################################
if [[ -f pyproject.toml ]]; then
  echo "⚠️  Found an existing pyproject.toml."
  read -p "Overwrite it with a new project scaffold? [y/n]: " OVERWRITE
  if [[ "$OVERWRITE" == "y" ]]; then
    rm -f pyproject.toml
    echo "✅ Removed old pyproject.toml."
  else
    echo "❌ Exiting. Run in a fresh folder or allow overwrite."
    exit 1
  fi
fi

#################################
# 1. Collect Project Metadata   #
#################################
read -p "📛 Project name: " PROJECT_NAME
read -p "🧾 Description: " DESCRIPTION
read -p "👤 Author name: " AUTHOR_NAME
read -p "📧 Author email: " AUTHOR_EMAIL
read -p "🐍 Python version [>=3.9]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-">=3.9"}
read -p "📁 Source folder [src]: " SRC_FOLDER
SRC_FOLDER=${SRC_FOLDER:-"src"}

############################################################
# 2. Ask If We Should Add Standard Dependencies via Poetry #
############################################################
read -p "📦 Add default ML dependencies (torch, hydra-core, pytorch-lightning)? [Y/n]: " ADD_DEFAULT_DEPS
ADD_DEFAULT_DEPS=${ADD_DEFAULT_DEPS:-"y"}  # default "yes"

read -p "📊 Add data science libs (numpy, pandas, matplotlib, etc)? [Y/n]: " ADD_DS
ADD_DS=${ADD_DS:-"y"}  # default "yes"

read -p "⚙️  Add dev dependencies (pytest, jupyter, ipykernel, wandb)? [Y/n]: " ADD_DEV_DEPS
ADD_DEV_DEPS=${ADD_DEV_DEPS:-"y"}  # default "yes"

#######################################
# 3. Write a Minimal pyproject.toml   #
#######################################
cat <<EOF > pyproject.toml
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$DESCRIPTION"
authors = [{ name = "$AUTHOR_NAME", email = "$AUTHOR_EMAIL" }]
readme = "README.md"
requires-python = "$PYTHON_VERSION"
# Minimal placeholder for dependencies
dependencies = []

# Telling Poetry how to find our package code
packages = [{ include = "$PROJECT_NAME", from = "$SRC_FOLDER" }]

[build-system]
requires = ["poetry-core>=1.5.0,<2.0.0"]
build-backend = "poetry.core.masonry.api"
EOF

##############################
# 4. Poetry Add Dependencies #
##############################
mkdir -p "$SRC_FOLDER/$PROJECT_NAME"
touch "$SRC_FOLDER/$PROJECT_NAME/__init__.py"

echo "📦 Installing base to create poetry.lock..."
poetry install

# Add default ML dependencies if "y"
if [[ "$ADD_DEFAULT_DEPS" =~ ^[Yy]$ ]]; then
  echo "📦 Adding ML deps with version pinning..."
  poetry add torch torchvision hydra-core pytorch-lightning
fi

# Add data-science packages if "y"
if [[ "$ADD_DS" =~ ^[Yy]$ ]]; then
  echo "📊 Adding data science deps..."
  poetry add numpy pandas matplotlib tqdm scikit-learn seaborn
fi

# Add dev dependencies if "y"
if [[ "$ADD_DEV_DEPS" =~ ^[Yy]$ ]]; then
  echo "⚙️  Adding dev tools..."
  poetry add --group dev pytest jupyter ipykernel wandb
fi

# Validate final pyproject
echo "🔍 Validating pyproject.toml..."
poetry check

###################################
# 5. Create Source Code Scaffold  #
###################################
mkdir -p "$SRC_FOLDER/$PROJECT_NAME"
touch "$SRC_FOLDER/$PROJECT_NAME/__init__.py"

echo "📝 Your pyproject.toml now contains pinned versions from 'poetry add'."

###################################
# 6. Adding pre-commit + linters  #
###################################
echo
echo "=== 🔧 Pre-commit and Linters Setup ==="
read -p "Add Black for code formatting? [Y/n]: " ADD_BLACK
ADD_BLACK=${ADD_BLACK:-"y"}

read -p "Add isort for import sorting? [Y/n]: " ADD_ISORT
ADD_ISORT=${ADD_ISORT:-"y"}

read -p "Add yamllint for YAML checks? [y/N]: " ADD_YAMLLINT
ADD_YAMLLINT=${ADD_YAMLLINT:-"n"}

# We assume we ALWAYS want ruff + pre-commit
poetry add --group dev pre-commit ruff

if [[ "$ADD_BLACK" =~ ^[Yy]$ ]]; then
  poetry add --group dev black
fi

if [[ "$ADD_ISORT" =~ ^[Yy]$ ]]; then
  poetry add --group dev isort
fi

if [[ "$ADD_YAMLLINT" =~ ^[Yy]$ ]]; then
  poetry add --group dev yamllint
fi

# Build up a .pre-commit-config.yaml in a variable
PRE_COMMIT_CONTENT="repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
"

if [[ "$ADD_BLACK" =~ ^[Yy]$ ]]; then
PRE_COMMIT_CONTENT+="
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3
"
fi

if [[ "$ADD_ISORT" =~ ^[Yy]$ ]]; then
PRE_COMMIT_CONTENT+="
  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        language_version: python3
"
fi

if [[ "$ADD_YAMLLINT" =~ ^[Yy]$ ]]; then
PRE_COMMIT_CONTENT+="
  - repo: https://github.com/adrienverge/yamllint.git
    rev: v1.31.0
    hooks:
      - id: yamllint
"
fi

# If there's an existing config, ask to overwrite or append
if [[ -f .pre-commit-config.yaml ]]; then
  echo "⚠️  .pre-commit-config.yaml already exists."
  read -p "Overwrite [o], append [a], or skip [s]? [o/a/s]: " PC_CHOICE
  case "$PC_CHOICE" in
    o|O)
      echo "Overwriting .pre-commit-config.yaml..."
      echo "$PRE_COMMIT_CONTENT" > .pre-commit-config.yaml
      ;;
    a|A)
      echo "Appending to .pre-commit-config.yaml..."
      echo "" >> .pre-commit-config.yaml
      echo "$PRE_COMMIT_CONTENT" >> .pre-commit-config.yaml
      ;;
    s|S)
      echo "Skipping .pre-commit-config.yaml changes."
      ;;
    *)
      echo "Invalid choice; skipping."
      ;;
  esac
else
  echo "📝 Writing .pre-commit-config.yaml..."
  echo "$PRE_COMMIT_CONTENT" > .pre-commit-config.yaml
fi

# Install or update the pre-commit hooks
if [[ -f .pre-commit-config.yaml ]]; then
  echo "⚙️  Installing pre-commit Git hook..."
  poetry run pre-commit install
  echo "✅ Running pre-commit on all files once..."
  poetry run pre-commit run --all-files
  echo "🧹 Pre-commit + linters setup complete."
else
  echo "❌ Skipped creating .pre-commit-config.yaml, so no hooks installed."
fi

echo "🚀 Setup script complete!"
