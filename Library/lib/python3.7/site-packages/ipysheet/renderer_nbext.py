def _jupyter_nbextension_paths():  # pragma: no cover
    return [{
        'section': 'notebook',
        'src': 'static',
        'dest': 'ipysheet-renderer',
        'require': 'ipysheet/extension-renderer'
    }]
