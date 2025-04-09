import os 
from typing import Any, Dict

import matplotlib
import matplotlib.axes
import matplotlib.figure
import numpy as np
import wandb
from pytorch_lightning.loggers import WandbLogger, TensorBoardLogger, Logger
from PIL import Image

class UnifiedExperiment:
    """
    A unified experiment wrapper that converts log entries to the appropriate format
    for the underlying logging backend (Wandb or TensorBoard).

    :param experiment: The underlying experiment object. For Wandb, this is a wandb.Run.
                       For TensorBoard, this is a SummaryWriter.
    :param backend: A string indicating the logging backend ('wandb' or 'tensorboard').
    """
    def __init__(self, experiment, backend):
        self._backend = backend
        self._experiment = experiment

    @staticmethod
    def _flatten_dict(d: Dict[Any, Any], parent_key: str = "", separator: str = "/") -> Dict[Any, Any]:
        """
        Recursively flattens a nested dictionary.
        """
        items = {}
        for k, v in d.items():
            new_key = f"{parent_key}{separator}{k}" if parent_key else k
            if isinstance(v, dict):
                items.update(UnifiedExperiment._flatten_dict(v, new_key, separator))
            else:
                items[new_key] = v
        return items

    def log(self, data: Dict[Any, Any]):
        """
        Log a dictionary of data to the underlying backend, converting figures and arrays as needed.
        If using TensorBoard, nested dictionaries are flattened.

        :param data: Dictionary of items to log. Can include:
                     - Matplotlib figures: will be converted to wandb.Image for Wandb or added via add_figure for TensorBoard.
                     - NumPy arrays: assumed to be images for TensorBoard via add_image.
                     - Scalars: logged via add_scalar in TensorBoard.
                     Optionally, an 'epoch' key can be included to specify the global step.
        """
        step = data.pop("epoch", None)
        data = self._flatten_dict(data)

        if self._backend == "wandb":
            # Wandb supports nested dictionaries natively.
            for key, value in data.items():
                if isinstance(value, matplotlib.axes.Axes):
                    value = value.get_figure()
                if isinstance(value, matplotlib.figure.Figure) or isinstance(value, Image.Image):
                    data[key] = wandb.Image(value)
            self._experiment.log(data)

        elif self._backend == "tensorboard":
            # Flatten nested dictionaries for TensorBoard.
            for key, value in data.items():

                if isinstance(value, matplotlib.axes.Axes):
                    value = value.get_figure()
                if isinstance(value, matplotlib.figure.Figure):
                    self._experiment.add_figure(tag=key, figure=value, global_step=step)
                elif isinstance(value, np.ndarray):
                    # Assumes image is a numpy array with shape (H, W, C); adjust dataformats if needed.
                    self._experiment.add_image(tag=key, img_tensor=value, global_step=step, dataformats="HWC")
                elif isinstance(value, Image.Image):
                    self._experiment.add_image(tag=key, img_tensor=np.array(value), global_step=step, dataformats="HWC")
                elif np.isscalar(value) and not isinstance(value, str):
                    self._experiment.add_scalar(tag=key, scalar_value=value, global_step=step)
                else:
                    # Extend handling for other data types if necessary.
                    pass

class UnifiedLogger(Logger):
    """
    A unified logger that wraps around WandbLogger or TensorBoardLogger, providing a consistent interface.
    Logging calls are delegated to the appropriate backend, converting data formats as needed.

    :param backend: A string indicating which backend to use ('wandb' or 'tensorboard').
    :param kwargs: Additional keyword arguments to pass to the underlying logger.
    """
    def __init__(self, backend, **kwargs):
        super().__init__()
        self._backend = backend
        if backend == "wandb":
            wandb.login(key=os.getenv("WANDB_API_KEY"))
            self._logger = WandbLogger(**kwargs)
        elif backend == "tensorboard":
            self._logger = TensorBoardLogger(**kwargs)
        else:
            raise ValueError("Unsupported backend: {}".format(backend))
        # Wrap the underlying experiment with the unified interface.
        self._experiment = UnifiedExperiment(self._logger.experiment, backend)
        self.log_base_model = not backend == "tensorboard"

    @property
    def experiment(self):
        """
        Return the unified experiment instance that supports logging in the proper format.
        """
        return self._experiment

    @property
    def name(self):
        """
        Return the name of the underlying logger.
        """
        return self._logger.name

    @property
    def version(self):
        """
        Return the version of the underlying logger.
        """
        return self._logger.version

    def log(self, data: Any):
        """
        Log data using the unified experiment interface.
        """
        self._experiment.log(data)

    def log_hyperparams(self, params):
        """
        Log hyperparameters using the underlying logger.

        :param params: A dictionary of hyperparameters.
        """
        if self.log_base_model:
            self._logger.log_hyperparams(params)

    def log_metrics(self, metrics, step=None):
        """
        Log metrics using the underlying logger.

        :param metrics: A dictionary of metric values.
        :param step: (Optional) Global step value.
        """
        self._logger.log_metrics(metrics, step)

    def save(self):
        """
        Save the logger state if the underlying logger supports saving.
        """
        if hasattr(self._logger, "save"):
            self._logger.save()

    def close(self):
        if self._backend == "wandb":
            wandb.finish()