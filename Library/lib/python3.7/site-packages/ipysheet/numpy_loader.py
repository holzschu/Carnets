from .easy import sheet, column, cell_range
from .utils import extract_data


def from_array(array):
    """ Helper function for creating a sheet out of a NumPy Array

    Parameters
    ----------
    array : NumPy Array

    Returns
    -------
    sheet : Sheet widget

    Example
    -------

    >>> import numpy as np
    >>> from ipysheet import from_array
    >>>
    >>> arr = np.random.randn(6, 26)
    >>>
    >>> sheet = from_array(arr)
    >>> display(sheet)
    """
    if len(array.shape) > 2:
        raise RuntimeError('The NumPy Array should be of 1-D or 2-D')

    rows = array.shape[0]
    columns = 1 if len(array.shape) == 1 else array.shape[1]

    out_sheet = sheet(rows=rows, columns=columns)
    if columns == 1:
        column(0, array)
    else:
        cell_range(array)
    return out_sheet


def to_array(sheet):
    """ Helper function for creating a NumPy Array out of a sheet

    Parameters
    ----------
    sheet : Sheet widget

    Returns
    -------
    array : NumPy Array

    Example
    -------

    >>> import ipysheet
    >>>
    >>> sheet = ipysheet.sheet(rows=3, columns=4)
    >>> ipysheet.cell(0, 0, 'Hello')
    >>> ipysheet.cell(2, 0, 'World')
    >>>
    >>> arr = to_array(sheet)
    >>> display(arr)
    """
    import numpy as np

    data = extract_data(sheet)

    return np.array(
        [
            [cell['value'] for cell in row]
            for row in data
        ]
    )
