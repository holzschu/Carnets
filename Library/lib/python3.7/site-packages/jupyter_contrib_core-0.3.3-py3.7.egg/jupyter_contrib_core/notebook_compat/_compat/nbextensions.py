# -*- coding: utf-8 -*-
"""
Shim providing some notebook.nbextensions functions for versions < 4.2.0.

The main differences are:
 * check_nbextension public API function omitted as unused
 * all apps except BaseNBExtensionApp are omitted
 * some unused private API stuff omitted
 * all deprecated arguments are ignored, since we assume the caller knows what
   they're doing
 * docstrings limited to first line for brevity - we assume that if the caller
   is using the function, they're familiar with notebook 4.2 API
"""

# Original jupyter notebook source is
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

from __future__ import print_function

import copy
import os
import shutil
import tarfile
import zipfile

from ipython_genutils.path import ensure_dir_exists
from ipython_genutils.py3compat import cast_unicode_py2
from ipython_genutils.tempdir import TemporaryDirectory
from jupyter_core.application import JupyterApp
from jupyter_core.paths import (
    ENV_CONFIG_PATH, ENV_JUPYTER_PATH, SYSTEM_CONFIG_PATH, SYSTEM_JUPYTER_PATH,
    jupyter_config_dir, jupyter_data_dir,
)
from notebook.nbextensions import (
    ArgumentConflict, __version__, _safe_is_tarfile,
)
from tornado.log import LogFormatter
from traitlets import Bool
from traitlets.config.manager import BaseJSONConfigManager
from traitlets.utils.importstring import import_item

try:
    from urllib.parse import urlparse  # Py3
    from urllib.request import urlretrieve
except ImportError:
    from urlparse import urlparse
    from urllib import urlretrieve

# Constants for pretty printing
# Window doesn't support coloring in the commandline
GREEN_OK = '\033[32mOK\033[0m' if os.name != 'nt' else 'ok'
RED_X = '\033[31m X\033[0m' if os.name != 'nt' else ' X'
GREEN_ENABLED = '\033[32m enabled \033[0m' if os.name != 'nt' else 'enabled '
RED_DISABLED = '\033[31mdisabled\033[0m' if os.name != 'nt' else 'disabled'

NBCONFIG_SECTIONS = ['common', 'notebook', 'tree', 'edit', 'terminal']

# -----------------------------------------------------------------------------
# Public API - large parts omitted
# -----------------------------------------------------------------------------


# check_nbextension omitted as unused


def install_nbextension(path, overwrite=False, symlink=False,
                        user=False, prefix=None, nbextensions_dir=None,
                        destination=None, logger=None, sys_prefix=False):
    """Install a Javascript extension for the notebook."""

    # the actual path to which we eventually installed
    full_dest = None

    nbext = _get_nbextension_dir(
        user=user, sys_prefix=sys_prefix, prefix=prefix,
        nbextensions_dir=nbextensions_dir)
    # make sure nbextensions dir exists
    ensure_dir_exists(nbext)

    # forcing symlink parameter to False if os.symlink does not exist (e.g.,
    # on Windows machines running python 2)
    if not hasattr(os, 'symlink'):
        symlink = False

    if isinstance(path, (list, tuple)):
        raise TypeError("path must be a string pointing to a single extension "
                        "to install; call this function multiple times to "
                        "install multiple extensions")

    path = cast_unicode_py2(path)

    if path.startswith(('https://', 'http://')):
        if symlink:
            raise ValueError("Cannot symlink from URLs")
        # Given a URL, download it
        with TemporaryDirectory() as td:
            filename = urlparse(path).path.split('/')[-1]
            local_path = os.path.join(td, filename)
            if logger:
                logger.info("Downloading: %s -> %s" % (path, local_path))
            urlretrieve(path, local_path)
            # now install from the local copy
            full_dest = install_nbextension(
                local_path, overwrite=overwrite, symlink=symlink,
                nbextensions_dir=nbext, destination=destination, logger=logger)
    elif path.endswith('.zip') or _safe_is_tarfile(path):
        if symlink:
            raise ValueError("Cannot symlink from archives")
        if destination:
            raise ValueError("Cannot give destination for archives")
        if logger:
            logger.info("Extracting: %s -> %s" % (path, nbext))

        if path.endswith('.zip'):
            archive = zipfile.ZipFile(path)
        elif _safe_is_tarfile(path):
            archive = tarfile.open(path)
        archive.extractall(nbext)
        archive.close()
        # TODO: what to do here
        full_dest = None
    else:
        if not destination:
            destination = os.path.basename(path)
        destination = cast_unicode_py2(destination)
        full_dest = os.path.normpath(os.path.join(nbext, destination))
        if overwrite and os.path.lexists(full_dest):
            if logger:
                logger.info("Removing: %s" % full_dest)
            if os.path.isdir(full_dest) and not os.path.islink(full_dest):
                shutil.rmtree(full_dest)
            else:
                os.remove(full_dest)

        if symlink:
            path = os.path.abspath(path)
            if not os.path.exists(full_dest):
                if logger:
                    logger.info("Symlinking: %s -> %s" % (full_dest, path))
                os.symlink(path, full_dest)
        elif os.path.isdir(path):
            # end in path separator
            path = os.path.join(os.path.abspath(path), '')
            for parent, dirs, files in os.walk(path):
                dest_dir = os.path.join(full_dest, parent[len(path):])
                if not os.path.exists(dest_dir):
                    if logger:
                        logger.info("Making directory: %s" % dest_dir)
                    os.makedirs(dest_dir)
                for file in files:
                    src = os.path.join(parent, file)
                    dest_file = os.path.join(dest_dir, file)
                    _maybe_copy(src, dest_file, logger=logger)
        else:
            src = path
            _maybe_copy(src, full_dest, logger=logger)

    return full_dest


def install_nbextension_python(module, overwrite=False, symlink=False,
                               user=False, sys_prefix=False, prefix=None,
                               nbextensions_dir=None, logger=None):
    """Install an nbextension bundled in a Python package."""
    m, nbexts = _get_nbextension_metadata(module)
    base_path = os.path.split(m.__file__)[0]

    full_dests = []

    for nbext in nbexts:
        src = os.path.join(base_path, nbext['src'])
        dest = nbext['dest']

        if logger:
            logger.info("Installing %s -> %s" % (src, dest))
        full_dest = install_nbextension(
            src, overwrite=overwrite, symlink=symlink,
            user=user, sys_prefix=sys_prefix, prefix=prefix,
            nbextensions_dir=nbextensions_dir,
            destination=dest, logger=logger
        )
        validate_nbextension_python(nbext, full_dest, logger)
        full_dests.append(full_dest)

    return full_dests


def uninstall_nbextension(dest, require=None, user=False, sys_prefix=False,
                          prefix=None, nbextensions_dir=None, logger=None):
    """Uninstall a Javascript extension of the notebook."""
    nbext = _get_nbextension_dir(user=user, sys_prefix=sys_prefix,
                                 prefix=prefix,
                                 nbextensions_dir=nbextensions_dir)
    dest = cast_unicode_py2(dest)
    full_dest = os.path.join(nbext, dest)
    if os.path.lexists(full_dest):
        if logger:
            logger.info("Removing: %s" % full_dest)
        if os.path.isdir(full_dest) and not os.path.islink(full_dest):
            shutil.rmtree(full_dest)
        else:
            os.remove(full_dest)

    # Look through all of the config sections making sure that the nbextension
    # doesn't exist.
    config_dir = os.path.join(
        _get_config_dir(user=user, sys_prefix=sys_prefix), 'nbconfig')
    cm = BaseJSONConfigManager(config_dir=config_dir)
    if require:
        for section in NBCONFIG_SECTIONS:
            cm.update(section, {"load_extensions": {require: None}})


def uninstall_nbextension_python(module, user=False, sys_prefix=False,
                                 prefix=None, nbextensions_dir=None,
                                 logger=None):
    """Uninstall an nbextension bundled in a Python package."""
    m, nbexts = _get_nbextension_metadata(module)
    for nbext in nbexts:
        dest = nbext['dest']
        require = nbext['require']
        if logger:
            logger.info("Uninstalling {} {}".format(dest, require))
        uninstall_nbextension(dest, require, user=user, sys_prefix=sys_prefix,
                              prefix=prefix, nbextensions_dir=nbextensions_dir,
                              logger=logger)


def _set_nbextension_state(section, require, state,
                           user=True, sys_prefix=False, logger=None):
    """Set whether the section's frontend should require the nbextension."""
    user = False if sys_prefix else user
    config_dir = os.path.join(
        _get_config_dir(user=user, sys_prefix=sys_prefix), 'nbconfig')
    cm = BaseJSONConfigManager(config_dir=config_dir)
    if logger:
        logger.info("{} {} extension {}...".format(
            "Enabling" if state else "Disabling",
            section,
            require
        ))
    cm.update(section, {"load_extensions": {require: state}})

    validate_nbextension(require, logger=logger)

    return cm.get(section).get(require) == state


def _set_nbextension_state_python(state, module, user, sys_prefix,
                                  logger=None):
    """Enable or disable some nbextensions stored in a Python package."""
    m, nbexts = _get_nbextension_metadata(module)
    return [_set_nbextension_state(section=nbext["section"],
                                   require=nbext["require"],
                                   state=state,
                                   user=user, sys_prefix=sys_prefix,
                                   logger=logger)
            for nbext in nbexts]


def enable_nbextension(section, require, user=True, sys_prefix=False,
                       logger=None):
    """Enable a named nbextension."""
    return _set_nbextension_state(section=section, require=require,
                                  state=True,
                                  user=user, sys_prefix=sys_prefix,
                                  logger=logger)


def disable_nbextension(section, require, user=True, sys_prefix=False,
                        logger=None):
    """Disable a named nbextension."""
    return _set_nbextension_state(section=section, require=require,
                                  state=False,
                                  user=user, sys_prefix=sys_prefix,
                                  logger=logger)


def enable_nbextension_python(module, user=True, sys_prefix=False,
                              logger=None):
    """Enable some nbextensions associated with a Python module."""
    return _set_nbextension_state_python(True, module, user, sys_prefix,
                                         logger=logger)


def disable_nbextension_python(module, user=True, sys_prefix=False,
                               logger=None):
    """Disable some nbextensions associated with a Python module."""
    return _set_nbextension_state_python(False, module, user, sys_prefix,
                                         logger=logger)


def validate_nbextension(require, logger=None):
    """Validate a named nbextension."""
    warnings = []
    infos = []

    js_exists = False
    for exts in _nbextension_dirs():
        # Does the Javascript entrypoint actually exist on disk?
        js = u"{}.js".format(os.path.join(exts, *require.split("/")))
        js_exists = os.path.exists(js)
        if js_exists:
            break

    require_tmpl = u"        - require? {} {}"
    if js_exists:
        infos.append(require_tmpl.format(GREEN_OK, require))
    else:
        warnings.append(require_tmpl.format(RED_X, require))

    if logger:
        if warnings:
            logger.warning(u"      - Validating: problems found:")
            for msg in warnings:
                logger.warning(msg)
            for msg in infos:
                logger.info(msg)
        else:
            logger.info(u"      - Validating: {}".format(GREEN_OK))

    return warnings


def validate_nbextension_python(spec, full_dest, logger=None):
    """Assess the health of an installed nbextension."""
    infos = []
    warnings = []

    section = spec.get("section", None)
    if section in NBCONFIG_SECTIONS:
        infos.append(u"  {} section: {}".format(GREEN_OK, section))
    else:
        warnings.append(u"  {}  section: {}".format(RED_X, section))

    require = spec.get("require", None)
    if require is not None:
        require_path = os.path.join(
            full_dest[0:-len(spec["dest"])],
            u"{}.js".format(require))
        if os.path.exists(require_path):
            infos.append(u"  {} require: {}".format(GREEN_OK, require_path))
        else:
            warnings.append(u"  {}  require: {}".format(RED_X, require_path))

    if logger:
        if warnings:
            logger.warning("- Validating: problems found:")
            for msg in warnings:
                logger.warning(msg)
            for msg in infos:
                logger.info(msg)
            logger.warning(u"Full spec: {}".format(spec))
        else:
            logger.info(u"- Validating: {}".format(GREEN_OK))

    return warnings


# -----------------------------------------------------------------------------
# Applications. Many omitted from notebook version.
# -----------------------------------------------------------------------------


class BaseNBExtensionApp(JupyterApp):
    """Base nbextension installer app"""
    _log_formatter_cls = LogFormatter
    version = __version__

    flags = copy.deepcopy(JupyterApp.flags)
    flags.update({
        'user': ({
            'BaseNBExtensionApp': {
                'user': True,
            }}, 'Apply the operation only for the given user'
        ),
        'system': ({
            'BaseNBExtensionApp': {
                'user': False,
                'sys_prefix': False,
            }}, 'Apply the operation system-wide'
        ),
        'sys-prefix': ({
            'BaseNBExtensionApp': {
                'sys_prefix': True,
            }}, ('Use sys.prefix as the prefix for configuration operations ' +
                 'and installing nbextensions (for environments, packaging)')
        ),
        'py': ({
            'BaseNBExtensionApp': {
                'python': True,
            }}, 'Install from a Python package'
        )
    })
    flags['python'] = flags['py']
    flags.pop('y', None)
    flags.pop('generate-config', None)

    user = Bool(False, config=True, help="Whether to do a user install")
    sys_prefix = Bool(False, config=True,
                      help="Use the sys.prefix as the prefix")
    python = Bool(False, config=True, help="Install from a Python package")

    # stuff about verbose from notebook version omitted

    def _log_format_default(self):
        """A default format for messages"""
        return '%(message)s'

# -----------------------------------------------------------------------------
# Private API
# -----------------------------------------------------------------------------


def _should_copy(src, dest, logger=None):
    """Return whether a file should be copied."""
    if not os.path.exists(dest):
        return True
    if os.stat(src).st_mtime - os.stat(dest).st_mtime > 1e-6:
        # we add a fudge factor to work around a bug in python 2.x
        # that was fixed in python 3.x: http://bugs.python.org/issue12904
        if logger:
            logger.warn("Out of date: %s" % dest)
        return True
    if logger:
        logger.info("Up to date: %s" % dest)
    return False


def _maybe_copy(src, dest, logger=None):
    """Copy a file if it needs updating."""
    if _should_copy(src, dest, logger=logger):
        if logger:
            logger.info("Copying: %s -> %s" % (src, dest))
        shutil.copy2(src, dest)


def _get_nbextension_dir(user=False, sys_prefix=False, prefix=None,
                         nbextensions_dir=None):
    """Return the nbextension directory specified."""
    if sum(map(bool, [user, prefix, nbextensions_dir, sys_prefix])) > 1:
        raise ArgumentConflict(
            "cannot specify more than one of user, sys_prefix, prefix, "
            "or nbextensions_dir")
    if user:
        nbext = os.path.join(jupyter_data_dir(), u'nbextensions')
    elif sys_prefix:
        nbext = os.path.join(ENV_JUPYTER_PATH[0], u'nbextensions')
    elif prefix:
        nbext = os.path.join(prefix, 'share', 'jupyter', 'nbextensions')
    elif nbextensions_dir:
        nbext = nbextensions_dir
    else:
        nbext = os.path.join(SYSTEM_JUPYTER_PATH[0], 'nbextensions')
    return nbext


def _nbextension_dirs():
    """The possible locations of nbextensions."""
    return [
        os.path.join(jupyter_data_dir(), u'nbextensions'),
        os.path.join(ENV_JUPYTER_PATH[0], u'nbextensions'),
        os.path.join(SYSTEM_JUPYTER_PATH[0], 'nbextensions')
    ]


def _get_config_dir(user=False, sys_prefix=False):
    """Get the location of config files for the current context."""
    user = False if sys_prefix else user
    if user and sys_prefix:
        raise ArgumentConflict(
            "Cannot specify more than one of user or sys_prefix")
    if user:
        nbext = jupyter_config_dir()
    elif sys_prefix:
        nbext = ENV_CONFIG_PATH[0]
    else:
        nbext = SYSTEM_CONFIG_PATH[0]
    return nbext


def _get_nbextension_metadata(module):
    """Get the list of nbextension paths associated with a Python module."""
    m = import_item(module)
    if not hasattr(m, '_jupyter_nbextension_paths'):
        raise KeyError(
            'The Python module {} is not a valid nbextension'.format(module))
    nbexts = m._jupyter_nbextension_paths()
    return m, nbexts
