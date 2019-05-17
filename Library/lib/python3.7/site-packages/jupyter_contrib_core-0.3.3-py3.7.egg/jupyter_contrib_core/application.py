# coding: utf-8
"""
Common application classes for jupyter_contrib.

Including the root `jupyter-contrib` command.
"""

from __future__ import print_function

import sys

import pkg_resources
from jupyter_core.application import JupyterApp

from jupyter_contrib_core import __version__


class JupyterContribApp(JupyterApp):
    """Root level jupyter_contrib app."""

    name = 'jupyter contrib'
    version = __version__
    description = (
        'community-contributed spice for Jupyter Interactive Computing')

    def __init__(self, *args, **kwargs):
        self._refresh_subcommands()
        super(JupyterContribApp, self).__init__(*args, **kwargs)

    def _refresh_subcommands(self):
        """
        Finds subcommands which have registered entry points.

        Each entry point is a function which returns a subcommands-style dict,
        where the keys are the name of the subcommand, and the values are
        2-tuples containing the sub-application class, and a description of the
        subcommand's action.
        """
        group = 'jupyter_contrib_core.app.subcommands'
        new_subcommands = {}
        # import ipdb; ipdb.set_trace()
        for entrypoint in pkg_resources.iter_entry_points(group=group):
            get_subcommands_dict = entrypoint.load()
            new_subcommands.update(get_subcommands_dict())
        self.subcommands.clear()
        self.subcommands.update(new_subcommands)

    def start(self):
        """Perform the App's actions as configured"""
        super(JupyterContribApp, self).start()

        # The above should have called a subcommand and raised NoStart; if we
        # get here, it didn't, so we should self.log.info a message.
        self.print_help()
        subcmds = ", ".join(sorted(self.subcommands))
        sys.exit("Please supply at least one subcommand: %s" % subcmds)


main = JupyterContribApp.launch_instance

if __name__ == '__main__':  # pragma: no cover
    main()
