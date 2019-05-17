from ._version import version_info, __version__
from .sheet import Cell, Range, Sheet, Renderer
from .easy import *
from .pandas_loader import from_dataframe, to_dataframe
from .numpy_loader import from_array, to_array


def _jupyter_nbextension_paths():  # pragma: no cover
    return [{
        'section': 'notebook',
        'src': 'static',
        'dest': 'ipysheet',
        'require': 'ipysheet/extension'
    }]
