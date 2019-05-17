# -*- coding: utf-8 -*-
"""Shim providing notebook.serverextensions stuff for pre 4.2 versions."""

try:
    # notebook >= 4.2
    from notebook.serverextensions import (
        ToggleServerExtensionApp, toggle_serverextension_python,
    )
except ImportError:
    # notebook <4.2
    from ._compat.serverextensions import (
        ToggleServerExtensionApp, toggle_serverextension_python,
    )

try:
    # notebook >= 5.0
    from notebook.extensions import ArgumentConflict
except ImportError:
    try:
        # notebook 4.2.x
        from notebook.serverextensions import ArgumentConflict
    except ImportError:
        # notebook < 4.2
        from ._compat.serverextensions import ArgumentConflict


__all__ = [
    'ArgumentConflict', 'ToggleServerExtensionApp',
    'toggle_serverextension_python',
]
