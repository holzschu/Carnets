# coding: utf-8

from . import latex_envs


__version__ = '1.4.0'


def _jupyter_nbextension_paths():
    return [dict(
        section='notebook',
        # src is relative to current module
        src='static',
        # dest directory is in the `nbextensions/` namespace
        dest='latex_envs',
        # require is also in the `nbextensions/` namespace
        require='latex_envs/latex_envs',
    )]
