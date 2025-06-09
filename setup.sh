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
while true; do
  read -p "📛 Project name: " PROJECT_NAME
  
  # Convert spaces to underscores
  ORIGINAL_PROJECT_NAME="$PROJECT_NAME"
  PROJECT_NAME="${PROJECT_NAME// /_}"
  
  # Check for dashes and other invalid characters
  if [[ "$PROJECT_NAME" == *"-"* ]]; then
    echo "⚠️  Please remove the dash from the project name. Python does not allow dashes in package name."
  elif [[ "$PROJECT_NAME" =~ [^a-zA-Z0-9_] ]]; then
    echo "⚠️  Project name contains invalid characters. Only use letters, numbers, and underscores."
  elif [[ "$PROJECT_NAME" != "$ORIGINAL_PROJECT_NAME" ]]; then
    echo "ℹ️  Project name converted to: $PROJECT_NAME"
    read -p "Continue with this name? [Y/n]: " USE_CONVERTED
    USE_CONVERTED=${USE_CONVERTED:-"y"}
    if [[ "$USE_CONVERTED" =~ ^[Yy]$ ]]; then
      break
    fi
  else
    break
  fi
done

read -p "🧾 Description: " DESCRIPTION
read -p "👤 Author name: " AUTHOR_NAME
read -p "📧 Author email: " AUTHOR_EMAIL
read -p "🐍 Python version [>=3.10]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-">=3.10"}  # Use default if left blank
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
dependencies = []  

# Tell Poetry how to find the actual code
packages = [{ include = "$PROJECT_NAME", from = "$SRC_FOLDER" }]

[build-system]
requires = ["poetry-core>=1.5.0,<2.0.0"]
build-backend = "poetry.core.masonry.api"
EOF

##############################
# 3a. Create README.md file  #
##############################
echo "📝 Creating README.md file..."

cat <<EOF > README.md
# $PROJECT_NAME

$DESCRIPTION

## Setup

This project uses [Poetry](https://python-poetry.org/) for dependency management.

\`\`\`bash
# Install dependencies
poetry install

# Activate the virtual environment
poetry shell
\`\`\`

## Project Structure

\`\`\`
$SRC_FOLDER/
└── $PROJECT_NAME/
    ├── __init__.py
EOF

# Add experiment to README if enabled
if [[ "$COPY_EXPERIMENT" =~ ^[Yy]$ ]]; then
  cat <<EOF >> README.md
    ├── experiment/
    │   └── ...
EOF
fi

# Add logging to README if enabled
if [[ "$COPY_LOGGING" =~ ^[Yy]$ ]]; then
  cat <<EOF >> README.md
    ├── logging/
    │   └── ...
EOF
fi

# Close README structure
cat <<EOF >> README.md
\`\`\`

## Development

This project uses pre-commit hooks to ensure code quality. Run \`pre-commit install\` to set up the hooks.
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

echo "🧽 Removing templates "
rm -rf templates
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

###################################
# 7. Verification Step            #
###################################
echo
echo "=== 🔍 Verification of Setup ==="
echo "Checking for required files and directories..."

# List of files and directories to verify
VERIFICATION_PASSED=true

# Check source directory and main package
if [[ ! -d "$SRC_FOLDER/$PROJECT_NAME" ]]; then
  echo "❌ Source directory not found: $SRC_FOLDER/$PROJECT_NAME"
  VERIFICATION_PASSED=false
else
  echo "✅ Source directory created: $SRC_FOLDER/$PROJECT_NAME"
fi

# Check pyproject.toml
if [[ ! -f "pyproject.toml" ]]; then
  echo "❌ pyproject.toml not found!"
  VERIFICATION_PASSED=false
else
  echo "✅ pyproject.toml created"
fi

# Check poetry.lock
if [[ ! -f "poetry.lock" ]]; then
  echo "❌ poetry.lock not found! Dependencies may not be installed correctly."
  VERIFICATION_PASSED=false
else
  echo "✅ poetry.lock created"
fi

# Check README.md
if [[ ! -f "README.md" ]]; then
  echo "❌ README.md not found!"
  VERIFICATION_PASSED=false
else
  echo "✅ README.md created"
fi

# Check .gitignore
if [[ ! -f ".gitignore" ]]; then
  echo "❌ .gitignore not found!"
  VERIFICATION_PASSED=false
else
  echo "✅ .gitignore created"
fi

# Check pre-commit config
if [[ ! -f ".pre-commit-config.yaml" ]]; then
  echo "⚠️ .pre-commit-config.yaml not found - pre-commit may not be set up"
else
  echo "✅ .pre-commit-config.yaml created"
fi

# Check git setup
if [[ ! -d ".git" ]]; then
  echo "⚠️ Git repository not initialized"
else
  echo "✅ Git repository initialized"
fi

# Check if experiment folder is created when expected
if [[ "$COPY_EXPERIMENT" =~ ^[Yy]$ && ! -d "$SRC_FOLDER/$PROJECT_NAME/experiment" ]]; then
  echo "❌ Experiment templates not copied correctly!"
  VERIFICATION_PASSED=false
elif [[ "$COPY_EXPERIMENT" =~ ^[Yy]$ ]]; then
  echo "✅ Experiment templates copied"
fi

# Check if logging folder is created when expected
if [[ "$COPY_LOGGING" =~ ^[Yy]$ && ! -d "$SRC_FOLDER/$PROJECT_NAME/logging" ]]; then
  echo "❌ Logging templates not copied correctly!"
  VERIFICATION_PASSED=false
elif [[ "$COPY_LOGGING" =~ ^[Yy]$ ]]; then
  echo "✅ Logging templates copied"
fi

# Final verification message
if [[ "$VERIFICATION_PASSED" == true ]]; then
  echo "✅ All critical files and directories verified!"
else
  echo "⚠️ Some files or directories are missing. Setup may be incomplete."
  echo "Please check the logs above for details."
  
  # Ask if user wants to continue despite verification issues
  read -p "Continue and finish setup anyway? [Y/n]: " CONTINUE_SETUP
  CONTINUE_SETUP=${CONTINUE_SETUP:-"y"}
  
  if [[ ! "$CONTINUE_SETUP" =~ ^[Yy]$ ]]; then
    echo "Setup aborted. Please fix the issues and try again."
    exit 1
  fi
fi

echo "🚀 Setup script complete!"

# Remove Setup Script
echo "🧹 Removing Setup Script"
rm -- "$0"
