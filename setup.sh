#!/bin/bash

# === Python Project Setup Script ===
# This script bootstraps a deep learning project with Poetry.
# It optionally installs common dependencies and copies reusable boilerplate code.

echo "=== 🐍 Python Project Setup with Poetry ==="

########################################
# 0. Check for existing pyproject.toml #
########################################
# Prevents overwriting an existing project unless explicitly allowed.
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
# Ask the user for key information needed to scaffold the pyproject.toml
read -p "📛 Project name: " PROJECT_NAME
read -p "🧾 Description: " DESCRIPTION
read -p "👤 Author name: " AUTHOR_NAME
read -p "📧 Author email: " AUTHOR_EMAIL
read -p "🐍 Python version [>=3.9]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-">=3.9"}  # Use default if left blank
read -p "📁 Source folder [src]: " SRC_FOLDER
SRC_FOLDER=${SRC_FOLDER:-"src"}  # Default to "src" if not specified

############################################################
# 2. Ask If We Should Add Standard Dependencies via Poetry #
############################################################
# These dependencies are commonly used in ML/DL/data projects.
read -p "📦 Add default ML dependencies (torch, hydra-core, pytorch-lightning)? [Y/n]: " ADD_DEFAULT_DEPS
ADD_DEFAULT_DEPS=${ADD_DEFAULT_DEPS:-"y"}

read -p "📊 Add data science libs (numpy, pandas, matplotlib, etc)? [Y/n]: " ADD_DS
ADD_DS=${ADD_DS:-"y"}

read -p "⚙️  Add dev dependencies (pytest, jupyter, ipykernel, wandb)? [Y/n]: " ADD_DEV_DEPS
ADD_DEV_DEPS=${ADD_DEV_DEPS:-"y"}

#######################################
# 3. Write a Minimal pyproject.toml   #
#######################################
# Generates the pyproject.toml used by Poetry to define the package
cat <<EOF > pyproject.toml
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "$DESCRIPTION"
authors = [{ name = "$AUTHOR_NAME", email = "$AUTHOR_EMAIL" }]
readme = "README.md"
requires-python = "$PYTHON_VERSION"
dependencies = []  # Placeholder; real deps added later

# Tell Poetry how to find the actual code
packages = [{ include = "$PROJECT_NAME", from = "$SRC_FOLDER" }]

[build-system]
requires = ["poetry-core>=1.5.0,<2.0.0"]
build-backend = "poetry.core.masonry.api"
EOF

##############################
# 4. Copy Boilerplate Code   #
##############################
echo " Copying boilerplate code..."

# Create base project folder and init file
mkdir -p "$SRC_FOLDER/$PROJECT_NAME"
touch "$SRC_FOLDER/$PROJECT_NAME/__init__.py"

# Define where your templates are stored
TEMPLATE_DIR="./templates"

# Check if templates folder exists
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "❌ $TEMPLATE_DIR not found. Make sure you're running this from the root of the template repo."
  exit 1
fi

# Optionally copy experiment-related templates
read -p "📦 Copy experiment templates? [Y/n]: " COPY_EXPERIMENT
COPY_EXPERIMENT=${COPY_EXPERIMENT:-"y"}

if [[ "$COPY_EXPERIMENT" =~ ^[Yy]$ ]]; then
  echo "🔬 Copying experiment setup to $SRC_FOLDER/$PROJECT_NAME/experiment"
  mkdir -p "$SRC_FOLDER/$PROJECT_NAME/experiment"
  cp -r ./templates/experiment/* "$SRC_FOLDER/$PROJECT_NAME/experiment"
  touch "$SRC_FOLDER/$PROJECT_NAME/experiment/__init__.py"
fi

# Optionally copy logging utilities
read -p "📦 Copy logging templates? [Y/n]: " COPY_LOGGING
COPY_LOGGING=${COPY_LOGGING:-"y"}

if [[ "$COPY_LOGGING" =~ ^[Yy]$ ]]; then
  echo "🧠 Copying logging utils to $SRC_FOLDER/$PROJECT_NAME/logging"
  mkdir -p "$SRC_FOLDER/$PROJECT_NAME/logging"
  cp -r ./templates/logging/* "$SRC_FOLDER/$PROJECT_NAME/logging"
  touch "$SRC_FOLDER/$PROJECT_NAME/logging/__init__.py"
fi 

echo "🧽 Copying .gitignore "
cp ./templates/gitignore .gitignore

##############################
# 5. Poetry Add Dependencies #
##############################

echo "📦 Installing base to create poetry.lock..."
poetry install # Creates the virtual environment and lock file

# Add common ML packages
if [[ "$ADD_DEFAULT_DEPS" =~ ^[Yy]$ ]]; then
  echo "📦 Adding ML deps with version pinning..."
  poetry add torch torchvision hydra-core pytorch-lightning
fi

# Add common data science packages
if [[ "$ADD_DS" =~ ^[Yy]$ ]]; then
  echo "📊 Adding data science deps..."
  poetry add numpy pandas matplotlib tqdm scikit-learn seaborn
fi

# Add developer tools
if [[ "$ADD_DEV_DEPS" =~ ^[Yy]$ ]]; then
  echo "⚙️  Adding dev tools..."
  poetry add --group dev pytest jupyter ipykernel wandb
fi

# Validate that the pyproject.toml is still sane
echo "🔍 Validating pyproject.toml..."
poetry check

echo "📝 Your pyproject.toml now contains pinned versions from 'poetry add'."

###################################
# 6. Adding pre-commit + linters  #
###################################
echo
echo "=== 🔧 Pre-commit and Linters Setup ==="

# Prompt for optional linters/formatters
read -p "Add Black for code formatting? [Y/n]: " ADD_BLACK
ADD_BLACK=${ADD_BLACK:-"y"}

read -p "Add isort for import sorting? [Y/n]: " ADD_ISORT
ADD_ISORT=${ADD_ISORT:-"y"}

# Always add Ruff + pre-commit as a baseline
poetry add --group dev pre-commit ruff

# Add optional linters
if [[ "$ADD_BLACK" =~ ^[Yy]$ ]]; then
  poetry add --group dev black
fi

if [[ "$ADD_ISORT" =~ ^[Yy]$ ]]; then
  poetry add --group dev isort
fi

# Build pre-commit config from user selections
PRE_COMMIT_CONTENT="repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
"

# Append extra hooks based on user choice
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

# Handle existing pre-commit config safely
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

# Install and run pre-commit if config exists
if [[ -f .pre-commit-config.yaml ]]; then
  echo "⚙️  Installing pre-commit Git hook..."
  poetry run pre-commit install
  echo "✅ Running pre-commit on all files once..."
  poetry run pre-commit run --all-files
  echo "🧹 Pre-commit + linters setup complete."
else
  echo "❌ Skipped creating .pre-commit-config.yaml, so no hooks installed."
fi


# Check if running in a git repo and offer to reinitialize
if [ -d ".git" ]; then
    echo "📁 Found existing git repository"
    read -p "Would you like to reinitialize git (remove template history)? [Y/n]: " REINIT_GIT
    REINIT_GIT=${REINIT_GIT:-"y"}
    
    if [[ "$REINIT_GIT" =~ ^[Yy]$ ]]; then
        echo "🔄 Removing existing git history..."
        rm -rf .git
        git init
        echo "✅ Initialized fresh git repository"
    else
        echo "⏭️ Keeping existing git history"
    fi
fi

echo "🚀 Setup script complete!"
