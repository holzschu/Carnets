import ipywidgets as widgets
import traitlets
from traitlets import Unicode, CInt, List, Tuple, Instance, Union, Dict, Bool, Any

from .serializer import create_value_serializer
from .utils import transpose, adapt_value
from ._version import __version_js__

semver_range_frontend = "~" + __version_js__


@widgets.register('ipysheet.Cell')
class Cell(widgets.Widget):
    _model_name = Unicode('CellRangeModel').tag(sync=True)
    _model_module = Unicode('ipysheet').tag(sync=True)
    # _view_module_version = Unicode('^0.1.0').tag(sync=True)
    _model_module_version = Unicode(semver_range_frontend).tag(sync=True)
    # value = Union([Bool(), Unicode(), Float(), Int()], allow_none=True, default_value=None).tag(sync=True)
    value = Any().tag(sync=True, **create_value_serializer('value'))
    row_start = CInt(3).tag(sync=True)
    column_start = CInt(4).tag(sync=True)
    row_end = CInt(3).tag(sync=True)
    column_end = CInt(4).tag(sync=True)
    type = Unicode(None, allow_none=True).tag(sync=True)
    name = Unicode(None, allow_none=True).tag(sync=True)
    style = Dict({}).tag(sync=True)
    renderer = Unicode(None, allow_none=True).tag(sync=True)
    read_only = Bool(False).tag(sync=True)
    squeeze_row = Bool(True).tag(sync=True)
    squeeze_column = Bool(True).tag(sync=True)
    transpose = Bool(False).tag(sync=True)
    choice = List(Unicode(), allow_none=True, default_value=None).tag(sync=True)
    numeric_format = Unicode('0.[000]', allow_none=True).tag(sync=True)
    date_format = Unicode('YYYY/MM/DD', allow_none=True).tag(sync=True)

    @traitlets.validate('value')
    def _validate_value(self, proposal):
        value = proposal['value']

        original_value = value

        value = adapt_value(value)
        if self.squeeze_row:
            value = [value]
        try:
            len(value)
        except TypeError:
            raise ValueError('value shape is incorrect')
        if self.squeeze_column:
            value = [[k] for k in value]
        # print(self.squeeze_row, self.squeeze_column, value)
        try:
            len(value[0])
        except TypeError:
            raise ValueError('value shape is incorrect')
        if self.transpose:  # we just work with the 'correct' shape
            value = transpose(value)
        row_length = self.row_end - self.row_start + 1
        if row_length != len(value):
            raise ValueError("length or array (%d) doesn't match number of rows (%d)" % (len(value), row_length))
        column_length = self.column_end - self.column_start + 1
        for row in value:
            if column_length != len(row):
                raise ValueError("not a regular matrix, columns lengths differ")
        return original_value


# Bug in traitlets, it doesn't set it, which triggers the bug fixed here:
# https://github.com/jupyter-widgets/ipywidgets/pull/1675
# which is not released yet (7.0.2 should have it)
Cell.choice.default_value = None


@widgets.register('ipysheet.Range')
class Range(widgets.Widget):
    value = Union([List(), List(Instance(list))], default_value=[0, 1]).tag(sync=True)


@widgets.register('ipysheet.Sheet')
class Sheet(widgets.DOMWidget):
    """"""
    _view_name = Unicode('SheetView').tag(sync=True)
    _model_name = Unicode('SheetModel').tag(sync=True)
    _view_module = Unicode('ipysheet').tag(sync=True)
    _model_module = Unicode('ipysheet').tag(sync=True)
    _view_module_version = Unicode(semver_range_frontend).tag(sync=True)
    _model_module_version = Unicode(semver_range_frontend).tag(sync=True)
    rows = CInt(3).tag(sync=True)
    columns = CInt(4).tag(sync=True)
    cells = Tuple().tag(sync=True, **widgets.widget_serialization)
    named_cells = Dict(value={}, allow_none=False).tag(sync=True, **widgets.widget_serialization)
    row_headers = Union([Bool(), List(Unicode())], default_value=True).tag(sync=True)
    column_headers = Union([Bool(), List(Unicode())], default_value=True).tag(sync=True)
    stretch_headers = Unicode('all').tag(sync=True)
    column_width = Union([CInt(), List(CInt())], default_value=None, allow_none=True).tag(sync=True)
    column_resizing = Bool(True).tag(sync=True)
    row_resizing = Bool(True).tag(sync=True)

    def __getitem__(self, item):
        '''Gets a previously created cell at row and column

        Example:

        >>> sheet = ipysheet.sheet(rows=10, columns=5)
        >>> cell = ipysheet.cell(2,0, value='hello')
        >>> assert sheet[2,0] is cell
        >>> sheet[2,0].value = 'bonjour'

        '''
        row, column = item
        for cell in self.cells:
            if cell.row_start == row and cell.column_start == column \
               and cell.row_end == row and cell.column_end == column:
                return cell
        raise IndexError('no cell was previously created for (row, index) = (%s, %s)'.format(row, column))


class Renderer(widgets.Widget):
    _model_name = Unicode('RendererModel').tag(sync=True)
    _view_module = Unicode('ipysheet/renderer').tag(sync=True)
    _model_module = Unicode('ipysheet/renderer').tag(sync=True)
    _view_module_version = Unicode(semver_range_frontend).tag(sync=True)
    _model_module_version = Unicode(semver_range_frontend).tag(sync=True)
    name = Unicode('custom').tag(sync=True)
    code = Unicode('').tag(sync=True)
