# Project Template

**TL;DR**:  
Use this template for data science projects. It comes with:
- **Poetry** for dependency management
- **Hydra** for composable configurations
- **PyTorch Lightning** + **PyTorch** for deep learning
- **WandB** for experiment tracking
- Pre-configured **linters** for code quality

---

## Features

- **Poetry Environment**: Reproducible builds and easy package installation.  
- **Hydra Configs**: Composable YAMLs for flexible experiment management.  
- **WandB**: (Optional) track experiments, logs, hyperparameters.  
- **Lightning + Torch**: Streamlined deep learning workflows.  
- **Linters**: E.g., `flake8` to maintain consistent style.

## Quick Start

1. **Install Poetry**  
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -

```poetry install
poetry shell
```

2. **Set Up**
``` bash ./setup.sh ```

### Hydra Structure
```
.
├─ configs/
│   ├─ config.yaml         # Merges sub-configs
│   ├─ model/
│   │   └─ default.yaml
│   ├─ dataset/
│   │   └─ default.yaml
│   ├─ logging/
│   │   └─ default.yaml
│   └─ experiment/
│       └─ default.yaml
```