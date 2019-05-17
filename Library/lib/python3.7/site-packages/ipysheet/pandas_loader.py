from .sheet import Cell, Sheet
from .utils import extract_data


def _get_cell_type(dt):
    # TODO Differentiate integer and float? Using custom renderers and
    # validators for integers?
    # Add support for void type from NumPy?
    # See https://handsontable.com/docs/6.2.2/tutorial-cell-types.html
    return {
        'b': 'checkbox',
        'i': 'numeric',
        'u': 'numeric',
        'f': 'numeric',
        'm': 'numeric',
        'M': 'date',
        'S': 'text',
        'U': 'text'
    }.get(dt.kind, 'text')


def _format_date(date):
    import pandas as pd

    return pd.to_datetime(str(date)).strftime('%Y/%m/%d')


def _get_cell_value(arr):
    if (arr.dtype.kind == 'M'):
        return [_format_date(date) for date in arr]
    else:
        return arr.tolist()


def from_dataframe(dataframe):
    """ Helper function for creating a sheet out of a Pandas DataFrame

    Parameters
    ----------
    dataframe : Pandas DataFrame

    Returns
    -------
    sheet : Sheet widget

    Example
    -------

    >>> import numpy as np
    >>> import pandas as pd
    >>> from ipysheet import from_dataframe
    >>>
    >>> dates = pd.date_range('20130101', periods=6)
    >>> df = pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list('ABCD'))
    >>>
    >>> sheet = from_dataframe(df)
    >>> display(sheet)
    """
    import numpy as np

    # According to pandas documentation: "NumPy arrays have one dtype for the
    # entire array, while pandas DataFrames have one dtype per column", so it
    # makes more sense to create the sheet and fill it column-wise
    columns = dataframe.columns.tolist()
    rows = dataframe.index.tolist()
    cells = []

    idx = 0
    for c in columns:
        arr = np.array(dataframe[c].values)
        cells.append(Cell(
            value=_get_cell_value(arr),
            row_start=0,
            row_end=len(rows) - 1,
            column_start=idx,
            column_end=idx,
            type=_get_cell_type(arr.dtype),
            squeeze_row=False,
            squeeze_column=True
        ))
        idx += 1

    return Sheet(
        rows=len(rows),
        columns=len(columns),
        cells=cells,
        row_headers=[str(header) for header in rows],
        column_headers=[str(header) for header in columns]
    )


def _extract_column(data, idx):
    import numpy as np
    import pandas as pd

    type = data[0][idx]['options'].get('type', 'text')
    arr = [row[idx]['value'] for row in data]

    if type == 'date':
        d = pd.to_datetime(arr)

        return np.array(d, dtype='M')
    elif type == 'widget':
        return np.array([wid.value for wid in arr], dtype='f')
    else:
        return np.array(arr)


def to_dataframe(sheet):
    """ Helper function for creating a Pandas DataFrame out of a sheet

    Parameters
    ----------
    sheet : Sheet widget

    Returns
    -------
    dataframe : Pandas DataFrame

    Example
    -------

    >>> import ipysheet
    >>>
    >>> sheet = ipysheet.sheet(rows=3, columns=4)
    >>> ipysheet.cell(0, 0, 'Hello')
    >>> ipysheet.cell(2, 0, 'World')
    >>>
    >>> df = to_dataframe(sheet)
    >>> display(df)
    """
    import pandas as pd

    data = extract_data(sheet)

    if len(data) == 0:
        return pd.DataFrame()

    if (type(sheet.column_headers) == bool):
        column_headers = [chr(ord('A') + i) for i in range(len(data[0]))]
    else:
        column_headers = list(sheet.column_headers)

    if (type(sheet.row_headers) == bool):
        row_headers = [i for i in range(len(data))]
    else:
        row_headers = list(sheet.row_headers)

    return pd.DataFrame(
        {
            header: _extract_column(data, idx)
            for idx, header in enumerate(column_headers)
        },
        index=row_headers,
        columns=column_headers
    )
