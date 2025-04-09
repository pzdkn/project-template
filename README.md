# 🚀 Project Template 

This repository provides a structured template for machine learning and deep learning projects. It includes a setup script that automates environment creation, dependency installation, code quality configuration, and boilerplate injection.

## ✨ Features

* 🛠️ Poetry-based environment management with reproducible lockfiles
* ⚡ PyTorch Lightning and Torch for model training workflows
* 🧩 Hydra for modular and composable configuration management
* 📈 Optional integration with Weights & Biases (WandB) for experiment tracking
* 🗂️ Unified logging wrapper compatible with WandB and TensorBoard
* 🧹 Pre-configured pre-commit hooks for code formatting and linting

## 🏃‍♂️ Quick Start

1. Install Poetry
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   ```

2. Run the setup script
   ```bash
   bash setup.sh
   ```

   During setup, you will be prompted to enter:
   * Project name and metadata
   * Preferred source folder (default: src)
   * Whether to include default ML, data science, and developer dependencies
   * Whether to include experiment and logging templates
   * Which code linters to use 

3. Activate the virtual environment
   ```bash
   poetry shell
   ```

## 🔧 Configuration Structure (Hydra)

The Hydra configuration follows a modular layout:

```
.
├── configs
│   ├── config.yaml
│   ├── model/
│   │   └── default.yaml
│   ├── dataset/
│   │   └── default.yaml
│   ├── logging/
│   │   └── default.yaml
│   └── experiment/
│       └── default.yaml
```

## 📝 Notes

* Your project code will live in `src/your_project_name/`
* The project is installed in editable mode by default
* Pre-commit hooks are installed automatically if selected during setup

This template is designed to streamline early development and promote reproducible, clean, and maintainable workflows! 💯