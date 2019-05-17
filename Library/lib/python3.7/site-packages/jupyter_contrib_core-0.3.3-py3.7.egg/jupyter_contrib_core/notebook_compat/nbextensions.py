# -*- coding: utf-8 -*-
"""Shim providing notebook.nbextensions stuff from 4.2 for earlier versions."""

try:
    # notebook >= 5.0
    from notebook.extensions import BaseExtensionApp
    BaseNBExtensionApp = BaseExtensionApp
except ImportError as err:
    try:
        from notebook.nbextensions import BaseNBExtensionApp
    except ImportError as err:
        from ._compat.nbextensions import BaseNBExtensionApp
    BaseExtensionApp = BaseNBExtensionApp

try:
    from notebook.nbextensions import _nbextension_dirs
except ImportError as err:
    from ._compat.nbextensions import _nbextension_dirs

try:
    from notebook.nbextensions import (
        # constants
        GREEN_ENABLED, GREEN_OK, NBCONFIG_SECTIONS, RED_DISABLED, RED_X,
        # Apps & classes
        ArgumentConflict,
        # public API functions
        _set_nbextension_state, _set_nbextension_state_python,
        disable_nbextension, disable_nbextension_python,
        enable_nbextension, enable_nbextension_python,
        install_nbextension, install_nbextension_python,
        uninstall_nbextension, uninstall_nbextension_python,
        validate_nbextension, validate_nbextension_python,
        # private API functions
        _get_nbextension_dir, _get_config_dir,
        _get_nbextension_metadata,
    )
except ImportError as err:
    from ._compat.nbextensions import (
        # constants
        GREEN_ENABLED, GREEN_OK, NBCONFIG_SECTIONS, RED_DISABLED, RED_X,
        # Apps & classes
        ArgumentConflict,
        # public API functions
        _set_nbextension_state, _set_nbextension_state_python,
        disable_nbextension, disable_nbextension_python,
        enable_nbextension, enable_nbextension_python,
        install_nbextension, install_nbextension_python,
        uninstall_nbextension, uninstall_nbextension_python,
        validate_nbextension, validate_nbextension_python,
        # private API functions
        _get_nbextension_dir, _get_config_dir,
        _get_nbextension_metadata,
    )

__all__ = [
    # constants
    'GREEN_ENABLED', 'GREEN_OK', 'NBCONFIG_SECTIONS', 'RED_DISABLED', 'RED_X',
    # Apps & classes
    'ArgumentConflict', 'BaseNBExtensionApp',
    # public API functions
    '_set_nbextension_state', '_set_nbextension_state_python',
    'disable_nbextension', 'disable_nbextension_python',
    'enable_nbextension', 'enable_nbextension_python',
    'install_nbextension', 'install_nbextension_python',
    'uninstall_nbextension', 'uninstall_nbextension_python',
    'validate_nbextension', 'validate_nbextension_python',
    # private API functions
    '_get_nbextension_dir', '_nbextension_dirs', '_get_config_dir',
    '_get_nbextension_metadata',
]
