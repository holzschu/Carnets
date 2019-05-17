"""Easy context-based interface for generating a sheet and cells.

Comparible to matplotlib pylab interface, this interface keeps track of the current
sheet. Using the :ref:`cell` function, :ref:`Cell` widgets are added to the current sheet.
"""
__all__ = ['sheet', 'current', 'cell', 'calculation', 'row', 'column', 'cell_range', 'hold_cells', 'renderer']

import numbers
import six
from contextlib import contextmanager

import ipywidgets as widgets

from .sheet import Cell, Sheet, Renderer
from .utils import transpose as default_transpose
from .utils import adapt_value

_last_sheet = None
_sheets = {}  # maps from key to Sheet instance
_hold_cells = False  # when try (using hold_cells() it does not add cells directly)
_cells = ()  # cells that aren't added directly


def sheet(key=None, rows=5, columns=5, column_width=None, row_headers=True, column_headers=True,
          stretch_headers='all', cls=Sheet, **kwargs):
    """Creates a new Sheet instance or retrieves one registered with key, and sets this as the 'current'.

    If the key argument is given, and no sheet is created before with this key, it will be registered under
    this key. If this function is called again with the same key argument, that :ref:`Sheet` instance
    will be returned.

    Example:

    >>> sheet1 = ipysheet.sheet('key1')
    >>> sheet2 = ipysheet.sheet('key2')
    >>> assert sheet2 is ipysheet.current()
    >>> assert sheet1 is ipysheet.sheet('key1')
    >>> assert sheet1 is ipysheet.current()

    Parameters
    ----------
    key : any
        If not used before, register the sheet under this key. If used before, return the previous `Sheet` instance
        registered with this key.

    Returns
    -------
    Sheet
        The new sheet, or if key is given, the previously created sheet registered with this key.
    """
    global _last_sheet
    if isinstance(key, Sheet):
        _last_sheet = key
    elif key is None or key not in _sheets:
        _last_sheet = cls(rows=rows, columns=columns, column_width=column_width,
                          row_headers=row_headers, column_headers=column_headers,
                          stretch_headers=stretch_headers, **kwargs)
        if key is not None:
            _sheets[key] = _last_sheet
    else:
        _last_sheet = _sheets[key]
    return _last_sheet


def current():
    """Returns the current `Sheet` instance"""
    return _last_sheet


def cell(row, column, value=0., type=None, color=None, background_color=None,
         font_style=None, font_weight=None, style=None, label_left=None, choice=None,
         read_only=False, numeric_format='0.[000]', date_format='YYYY/MM/DD', renderer=None, **kwargs):
    """Adds a new `Cell` widget to the current sheet

    Parameters
    ----------
    row : int
        Zero based row index
    column : int
        Zero based column index
    type : string
        Type of cell, options are: text, numeric, checkbox, dropdown, numeric, date.
        If type is None, the type is inferred from the type of the value being passed,
        numeric (float or int type), boolean (bool type), or else text. When choise is given
        the type will be assumed to be dropdown.
        The types refer (currently) to the handsontable types:
          https://docs.handsontable.com/0.35.1/demo-custom-renderers.html
    """
    global _cells
    if type is None:
        if isinstance(value, bool):
            type = 'checkbox'
        elif isinstance(value, numbers.Number):
            type = 'numeric'
        elif isinstance(value, widgets.Widget):
            type = 'widget'
        else:
            type = 'text'
        if choice is not None:
            type = 'dropdown'

    style = style or {}
    if color is not None:
        style['color'] = color
    if background_color is not None:
        style['backgroundColor'] = background_color
    if font_style is not None:
        style['fontStyle'] = font_style
    if font_weight is not None:
        style['fontWeight'] = font_weight
    c = Cell(value=value, row_start=row, column_start=column, row_end=row, column_end=column,
             squeeze_row=True, squeeze_column=True, type=type, style=style, choice=choice,
             read_only=read_only, numeric_format=numeric_format, date_format=date_format,
             renderer=renderer, **kwargs)
    if _hold_cells:
        _cells += (c,)
    else:
        _last_sheet.cells = _last_sheet.cells+(c,)
    if label_left:
        if column-1 < 0:
            raise IndexError("cannot put label to the left of column 0")
        cell(row, column-1, value=label_left, font_weight='bold')
    return c


def row(row, value, type=None, column_start=0, column_end=None, choice=None,
        read_only=False, numeric_format='0.[000]', date_format='YYYY/MM/DD', renderer=None,
        color=None, background_color=None, font_style=None, font_weight=None, **kwargs):
    """Create a CellRange widget, representing multiple cells in a sheet, in a horizontal column

    Parameters
    ----------
    column : int
        Which rows, 0 based.
    value : list
        List of values for each cell.
    row_start : int
        Which row the column will start, default 0.
    row_end : int
        Which row the column will end, default is the last.

    Returns
    -------
        A CellRange widget.
    """
    return cell_range(value, column_start=column_start, column_end=column_end, row_start=row, row_end=row,
                      squeeze_row=True, squeeze_column=False,
                      color=color, background_color=background_color,
                      font_style=font_style, font_weight=font_weight, type=type, **kwargs)


def column(column, value, type=None, row_start=0, row_end=None,  choice=None,
           read_only=False, numeric_format='0.[000]', date_format='YYYY/MM/DD', renderer=None,
           color=None, background_color=None, font_style=None, font_weight=None, **kwargs):
    """Create a CellRange widget, representing multiple cells in a sheet, in a vertical column

    Parameters
    ----------
    column : int
        Which rows, 0 based.
    value : list
        List of values for each cell.
    row_start : int
        Which row the column will start, default 0.
    row_end : int
        Which row the column will end, default is the last.

    Returns
    -------
        A CellRange widget.
    """
    return cell_range(value, column_start=column, column_end=column, row_start=row_start, row_end=row_end,
                      squeeze_row=False, squeeze_column=True,
                      read_only=read_only, numeric_format=numeric_format, date_format=date_format, renderer=renderer,
                      color=color, background_color=background_color, type=type,
                      font_style=font_style, font_weight=font_weight, **kwargs)


def cell_range(value, row_start=0, column_start=0, row_end=None, column_end=None, transpose=False,
               squeeze_row=False, squeeze_column=False, type=None, choice=None,
               read_only=False, numeric_format='0.[000]', date_format='YYYY/MM/DD', renderer=None, style=None,
               color=None, background_color=None, font_style=None, font_weight=None, **kwargs):
    """Create a CellRange widget, representing multiple cells in a sheet, in a horizontal column

    Parameters
    ----------
    value : list of lists
        List of lists values for each cell.
    row_start : int
        Which rows to start, 0 based.
    column_start : int
        Which rows to start, 0 based.
    row_end : int
        Which row the column will end, default is the last.
    column_end : int
        Which row the column will end, default is the last.
    transpose : bool
        Interpret the value array as value[column_index][row_index]
    squeeze_row : bool
        Take out the row dimensions, meaning only value[column_index] is used
    squeeze_column : bool
        Take out the column dimensions, meaning only value[row_index] is used

    Returns
    -------
    Range
        A CellRange widget.
    """
    global _cells

    value_original = value

    value = adapt_value(value)
    # instead of an if statements, we just use T to transpose or not when needed
    T = (lambda x: x) if not transpose else default_transpose
    # we work with the optionally transposed values for simplicity
    value = T(value)
    if squeeze_row:
        value = [value]
    if squeeze_column:
        value = [[k] for k in value]
    if row_end is None:
        row_end = row_start + len(value) - 1
    row_length = row_end - row_start + 1
    if row_length != len(value):
        raise ValueError("length or array doesn't match number of rows")
    if row_length == 0:
        raise ValueError("0 rows not supported")
    if column_end is None:
        column_end = column_start + len(value[0]) - 1
    column_length = column_end - column_start + 1
    if column_length == 0:
        raise ValueError("0 columns not supported")
    for row in value:
        if column_length != len(row):
            raise ValueError("not a regular matrix, columns lengths differ")
    if row_start + row_length > _last_sheet.rows:
        raise ValueError("array will go outside of sheet, too many rows")
    if column_start + column_length > _last_sheet.columns:
        raise ValueError("array will go outside of sheet, too many columns")

    # see if we an infer a type from the data, otherwise leave it None
    if type is None:
        type_check_map = [('checkbox', lambda x: isinstance(x, bool)),
                          ('numeric', lambda x: isinstance(x, numbers.Number)),
                          ('text', lambda x: isinstance(x, six.string_types)),
                          ('widget', lambda x: isinstance(x, widgets.Widget)),
                          ]
        for type_check, check in type_check_map:
            checks = True  # ok until proven wrong
            for i in range(row_length):
                for j in range(column_length):
                    if not check(value[i][j]):
                        checks = False
            if checks:  # we found a matching type
                type = type_check
                break

    style = style or {}
    if color is not None:
        style['color'] = color
    if background_color is not None:
        style['backgroundColor'] = background_color
    if font_style is not None:
        style['fontStyle'] = font_style
    if font_weight is not None:
        style['fontWeight'] = font_weight

    c = Cell(value=value_original, row_start=row_start, column_start=column_start, row_end=row_end, column_end=column_end,
             squeeze_row=squeeze_row, squeeze_column=squeeze_column, transpose=transpose, type=type,
             read_only=read_only, choice=choice, renderer=renderer, numeric_format=numeric_format, date_format=date_format,
             style=style, **kwargs)
    if _hold_cells:
        _cells += (c,)
    else:
        _last_sheet.cells = _last_sheet.cells+(c,)
    return c


def renderer(code, name):
    """Adds a cell renderer (to the front end)

    Parameters
    ----------
    code : str or code or function objject
        If a string object, it is assumed to be a JavaScript snippet, else it is assumed
        to be a function or code object and will be transpiled to javascript using flexxui/pscript.
    name : name of the renderer
    """
    if not isinstance(code, six.string_types):
        from pscript import py2js
        code_transpiled = py2js(code, new_name='the_renderer', indent=4)
        code = '''
function() {
  %s
  return the_renderer

}()
''' % code_transpiled
    renderer = Renderer(code=code, name=name)
    return renderer


def _assign(object, value):
    if isinstance(object, widgets.Widget):
        object, trait = object, 'value'
    else:
        object, trait = object
    setattr(object, trait, value)


def calculation(inputs, output, initial_calculation=True):
    """A decorator that assigns to output widget a calculation depending on the input widgets

    Example that takes three input widgets and writes the output to a cell:

    >>> a = ipysheet.cell(0, 0, value=1)
    >>> b = ipysheet.cell(0, 0, value=widgets.IntSlider(value=2))
    >>> c = widgets.IntSlider(max=0)
    >>> d = ipysheet.cell(0, 0, value=1)
    >>> @ipysheet.calculation(inputs=[a, (b, 'value'), (c, 'max')], output=d)
    >>> def add(a, b, c):
    >>>     return a + b + c

    Parameters
    ----------
    inputs : list of widgets, or (widget, 'traitname') pairs
        List of all widget, whose values (default 'value', otherwise specified by 'traitname')
        are input of the function that is decorated
    output : widget or (widget, 'traitname')
        The output of the decorator function will be assigned to output.value or output.<traitname>.
    initial_calculation : bool
        When True the calculation will be done directly for the first time.
    """
    def decorator(f):
        def get_value(input):
            if isinstance(input, widgets.Widget):
                object, trait = input, 'value'
            else:
                object, trait = input  # assume it's a tup;e
            if isinstance(object, Cell) and isinstance(object.value, widgets.Widget):
                object = object.value
            return getattr(object, trait)

        def calculate(*ignore_args):
            values = map(get_value, inputs)
            result = f(*values)
            _assign(output, result)

        for input in inputs:
            if isinstance(input, widgets.Widget):
                object, trait = input, 'value'
            else:
                object, trait = input  # assume it's a tuple

            if isinstance(object, Cell) and isinstance(object.value, widgets.Widget):
                # when it is a cell which holds a widget, we actually want the widgets' value
                object.value.observe(calculate, trait)
            else:
                object.observe(calculate, trait)

            def handle_possible_widget_change(change, trait=trait):
                if isinstance(change['old'], widgets.Widget):
                    change['old'].unobserve(calculate, trait)
                if isinstance(change['new'], widgets.Widget):
                    change['new'].observe(calculate, trait)
                calculate()
            object.observe(handle_possible_widget_change, 'value')
        if initial_calculation:
            calculate()
    return decorator


@contextmanager
def hold_cells():
    """Hold adding any cell widgets until leaving this context.

    This may give a better performance when adding many cells.

    Example
    -------

    >>> ipsheet.sheet(rows=10,columns=10)
    >>> with ipysheet.hold_cells()
    >>>  for i in range(10):
    >>>    for j in range(10):
    >>>      ipysheet.cell(i,j, value=i*10+j)
    >>> # at this line, the Cell widgets are added
    """
    global _hold_cells
    global _cells
    if _hold_cells is True:
        yield
    else:
        try:
            _hold_cells = True
            yield
        finally:
            _hold_cells = False
            # print(_cells, _last_sheet.cells)
            _last_sheet.cells = tuple(_last_sheet.cells) + tuple(_cells)
            _cells = ()
