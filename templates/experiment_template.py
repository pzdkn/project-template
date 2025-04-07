# run_experiment.py

import os
import random
import numpy as np
import torch
from pathlib import Path

import hydra
from omegaconf import DictConfig, OmegaConf
from hydra.utils import instantiate

def run_experiment(model, dataset, logger, device, cfg):
    """
    Runs the main machine-learning experiment steps.
    
    This function is intended to be minimal and purely focused on whatever
    ML logic you have. In a real project, you'd:
      - Move 'model' to 'device'
      - Perform training loops
      - Evaluate performance
      - Log relevant metrics via 'logger'
      - Possibly save checkpoints, etc.
    
    Args:
        model: The instantiated model object (e.g., PyTorch model).
        dataset: The data object needed for training or evaluation.
        logger: A logger object for tracking experiment metrics, hyperparams, etc.
        device: A string or torch.device indicating where computations take place.
        cfg (DictConfig): The entire Hydra config, if you need to reference more params.
    """
    # Example usage demonstration; replace with your real ML steps:
    print(f"[run_experiment] device={device}, model={model}, dataset={dataset}")
    # (No actual training logic here, but you can add it as needed.)
    pass


@hydra.main(config_path="configs", config_name="config", version_base="1.1")
def main(cfg: DictConfig):
    """
    Hydra entry point: handles scaffolding (seed, directories, instantiation, logging).
    
    In this minimal example:
      1) We set seeds (if provided in cfg.seed).
      2) We create 'results_dir' and 'data_dir'.
      3) We instantiate 'logger', 'model', and 'dataset' from the config blocks.
      4) We log hyperparameters, then call run_experiment().
      5) We close the logger and finish.
    
    Partial Instantiation Example:
      If you have a config that only partially specifies a constructor
      and you plan to finalize arguments in code, you can do something like:
      
      >>> partial_obj = instantiate(cfg.some_config, _partial_=True)
      >>> # Now 'partial_obj' is a callable (a partial function).
      >>> final_obj = partial_obj(extra_arg=42, another_arg="hello")
      >>> # 'final_obj' is the fully constructed object.
      
    For real usage, adapt or remove any parts that do not suit your project.
    """
    
    # -------------------- 1. Seed Setup --------------------
    seed = cfg.get("seed", None)
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
        torch.manual_seed(seed)
        print(f"[main] Global seed set to {seed}")

    # -------------------- 2. Directory Preparation --------------------
    results_dir = Path(cfg.results_dir)
    data_dir = Path(cfg.data_dir)
    results_dir.mkdir(parents=True, exist_ok=True)
    data_dir.mkdir(parents=True, exist_ok=True)
    print(f"[main] results_dir: {results_dir}")
    print(f"[main] data_dir: {data_dir}")

    # -------------------- 3. Print Resolved Config --------------------
    # Always helpful for reproducibility
    print("[main] Full config:\n", OmegaConf.to_yaml(cfg, resolve=True))

    # -------------------- 4. Object Instantiation --------------------
    # (A) A logger, typically includes run_name/tags from the config
    logger = instantiate(cfg.logging)
    
    # (B) A model and dataset, each presumably has '_target_' in their config file
    model = instantiate(cfg.model)
    dataset = instantiate(cfg.dataset)

    # -------------------- Partial Instantiation Example --------------------
    # Suppose you have a config that doesn't fully specify the constructor arguments:
    #
    #  adapter:
    #    _target_: my_project.adapters.MyAdapter
    #    _partial_: true
    #    param1: 100
    #
    # You might do:
    #
    # >>> partial_adapter = instantiate(cfg.adapter)
    # >>> # partial_adapter is now a callable. We supply remaining args:
    # >>> adapter = partial_adapter(additional_arg="hello")
    #
    # If you don't need partial instantiation, remove or ignore this snippet.

    # (C) Log hyperparameters before the experiment
    logger.log_hyperparams(cfg)

    # -------------------- 5. Run the Experiment --------------------
    device = cfg.get("device", "cpu")
    run_experiment(
        model=model,
        dataset=dataset,
        logger=logger,
        device=device,
        cfg=cfg
    )

    # -------------------- 6. Clean Up --------------------
    logger.close()
    print("[main] Experiment completed.")


if __name__ == "__main__":
    main()
