import numpy as np
import pandas as pd
import ipysheet
import pytest
from ipysheet.utils import transpose
import ipywidgets as widgets
import ipykernel.kernelbase
from .utils import adapt_value


class _KernelMock(ipykernel.kernelbase.Kernel):
    @property
    def session(self):
        return self

    def send(self, *args, **kwargs):
        pass


@pytest.fixture
def kernel():
    return _KernelMock()


def test_transpose():
    assert transpose([[1, 2]]) == [[1], [2]]
    assert transpose([[1, 2], [3, 4]]) == [[1, 3], [2, 4]]
    assert transpose([[1], [2]]) == [[1, 2]]


def test_current_sheet():
    sheet1 = ipysheet.sheet()
    assert sheet1 is ipysheet.current()
    sheet2 = ipysheet.sheet()
    assert sheet2 is ipysheet.current()
    assert sheet1 is ipysheet.sheet(sheet1)
    assert sheet1 is ipysheet.current()

    sheet3 = ipysheet.sheet('key3')
    assert sheet3 is ipysheet.current()
    sheet4 = ipysheet.sheet('key4')
    assert sheet4 is ipysheet.current()
    assert sheet3 is ipysheet.sheet('key3')
    assert sheet3 is ipysheet.current()
    assert sheet4 is ipysheet.sheet('key4')
    assert sheet4 is ipysheet.current()


def test_cell_add():
    sheet1 = ipysheet.sheet()
    sheet2 = ipysheet.sheet()
    ipysheet.cell(0, 0, value='1')
    assert len(sheet1.cells) == 0
    assert len(sheet2.cells) == 1
    ipysheet.sheet(sheet1)
    ipysheet.cell(0, 0, value='2')
    ipysheet.cell(0, 1, value='2')
    assert len(sheet1.cells) == 2
    assert len(sheet2.cells) == 1

    with ipysheet.hold_cells():
        ipysheet.cell(1, 0, value='3')
        ipysheet.cell(1, 1, value='4')
        assert len(sheet1.cells) == 2
        assert len(sheet2.cells) == 1
    assert len(sheet1.cells) == 4
    assert len(sheet2.cells) == 1

    # nested hold cells
    sheet1 = ipysheet.sheet()
    with ipysheet.hold_cells():
        with ipysheet.hold_cells():
            ipysheet.cell(1, 0, value='3')
            ipysheet.cell(1, 1, value='4')
            assert len(sheet1.cells) == 0
        assert len(sheet1.cells) == 0
    assert len(sheet1.cells) == 2


def test_calculation():
    ipysheet.sheet()
    a = ipysheet.cell(0, 0, value=1)
    b = ipysheet.cell(0, 0, value=2)
    c = ipysheet.cell(0, 0, value=0)

    @ipysheet.calculation(inputs=[a, (b, 'value')], output=c)
    def add(a, b):  # pylint: disable=unused-variable
        return a + b

    assert c.value == 3
    a.value = 10
    assert c.value == 10 + 2
    b.value = 20
    assert c.value == 10 + 20

    a.value = 1
    b.value = 2
    assert c.row_start == 0

    @ipysheet.calculation(inputs=[a, b], output=(c, 'type'))
    def add2(a, b):  # pylint: disable=unused-variable
        return 'abcdefg'[a + b]

    assert c.type == 'd'
    b.value = 1
    assert c.type == 'c'

    ipysheet.sheet()
    a = ipysheet.cell(0, 0, value=1)
    b = ipysheet.cell(0, 0, value=widgets.IntSlider(value=2))
    c = widgets.IntSlider(max=0)
    d = ipysheet.cell(0, 0, value=1)

    @ipysheet.calculation(inputs=[a, (b, 'value'), (c, 'max')], output=d)
    def add3(a, b, c):  # pylint: disable=unused-variable
        return a + b + c

    assert d.value == 3
    a.value = 10
    assert d.value == 10+2
    b.value.value = 20
    assert d.value == 10+20
    c.max = 30
    assert d.value == 10+20+30

    b.value = widgets.IntSlider(value=2)
    assert d.value == 10+2+30
    b.value = 20
    assert d.value == 10+20+30

    a.value = widgets.IntSlider(value=100)
    assert d.value == 100+20+30
    a.value.value = 10
    assert d.value == 10+20+30


def test_getitem():
    sheet = ipysheet.sheet()
    cell00 = ipysheet.cell(0, 0, value='0_0')
    cell10 = ipysheet.cell(1, 0, value='1_0')
    cell21 = ipysheet.cell(2, 1, value='2_1')
    assert sheet[0, 0] is cell00
    assert sheet[1, 0] is cell10
    assert sheet[2, 1] is cell21
    with pytest.raises(IndexError):
        sheet[1, 1]
    # TODO: what do we do with copies.. ? now we return the first values
    ipysheet.cell(0, 0, value='0_0')
    assert sheet[0, 0] is cell00


def test_row_and_column():
    ipysheet.sheet(rows=3, columns=4)
    ipysheet.row(0, [0, 1, 2, 3])
    ipysheet.row(0, [0, 1, 2])
    ipysheet.row(0, [0, 1, 2], column_end=2)
    ipysheet.row(0, [0, 1, 2], column_start=1)
    with pytest.raises(ValueError):
        ipysheet.row(0, [0, 1, 2, 4, 5])
    with pytest.raises(ValueError):
        ipysheet.row(0, [0, 1], column_end=3)
    with pytest.raises(ValueError):
        ipysheet.row(0, [0, 1, 2, 4], column_start=1)

    row = ipysheet.row(0, [0, 1, 2, 3])
    with pytest.raises(ValueError):
        row.value = [0, 1, 2]
    with pytest.raises(ValueError):
        row.value = 1
    row.value = [0, 1, 2, 4]
    assert row.value == [0, 1, 2, 4]

    ipysheet.column(0, [0, 1, 2])
    ipysheet.column(0, [0, 1])
    ipysheet.column(0, [0, 1], row_end=1)
    ipysheet.column(0, [0, 1], row_start=1)
    with pytest.raises(ValueError):
        ipysheet.column(0, [0, 1, 2, 3])
    with pytest.raises(ValueError):
        ipysheet.column(0, [0, 1], row_end=0)
    with pytest.raises(ValueError):
        ipysheet.column(0, [0, 1, 2, 4], row_start=1)

    col = ipysheet.column(0, [0, 1, 2])
    with pytest.raises(ValueError):
        col.value = [0, 1]
    with pytest.raises(ValueError):
        col.value = 1
    col.value = [0, 1, 3]
    assert col.value == [0, 1, 3]


def test_cell_range():
    ipysheet.sheet(rows=3, columns=4)
    # [row][column]
    ipysheet.cell_range([[0, 1]])  # 1 row, 2 columns
    ipysheet.cell_range([[0], [2]])  # 2 rows, 1 columns
    ipysheet.cell_range([[0, 1], [2, 3]])  # 2 rows, 2 columns
    ipysheet.cell_range([[0, 1], [2, 3], [4, 5]])  # 3 rows, 2 columns
    ipysheet.cell_range([[0, 1, 9], [2, 3, 9], [4, 5, 9]])  # 3 rows, 3 columns
    ipysheet.cell_range([[0, 1, 9]], column_end=2)  # 3 rows, 3 columns
    ipysheet.cell_range([[0, 1, 9]], column_start=1)  # 1 rows, 3 columns
    with pytest.raises(ValueError):
        ipysheet.cell_range([[0, 1], [2, 3], [4, 5], [6, 7]])  # 4 rows, 2 columns
    with pytest.raises(ValueError):
        ipysheet.cell_range([[0, 1, 2, 3, 4], [2, 3, 4, 5, 6], [3, 4, 5, 6, 7]])  # 3 rows, 5 columns
    with pytest.raises(ValueError):
        ipysheet.cell_range([[0, 1, 2, 3, 4], [2], [3, 4, 5, 6, 7]])  # not well shaped
    with pytest.raises(ValueError):
        ipysheet.cell_range([])  # empty rows
    with pytest.raises(ValueError):
        ipysheet.cell_range([[], []])  # empty columns

    value = [[0, 1], [2, 3], [4, 5]]
    valueT = [[0, 2, 4], [1, 3, 5]]  # it's transpose
    assert value == transpose(valueT)
    r = ipysheet.cell_range(value)  # 3 rows, 2 columns
    with pytest.raises(ValueError):
        r.value = 1
    with pytest.raises(ValueError):
        r.value = [1, 2, 3]
    with pytest.raises(ValueError):
        r.value = [[1, 2]]
    assert r.value == transpose(valueT)

    rT = ipysheet.cell_range(valueT, transpose=True)  # 3 rows, 2 columns
    with pytest.raises(ValueError):
        rT.value = 1
    with pytest.raises(ValueError):
        rT.value = [1, 2, 3]
    with pytest.raises(ValueError):
        rT.value = [[1, 2]]
    rT.value = transpose(value)
    assert rT.value == transpose(value)

    sheet = ipysheet.sheet(rows=3, columns=4)
    assert len(sheet.cells) == 0
    with ipysheet.hold_cells():
        ipysheet.cell_range(value)
        ipysheet.cell_range(value)
        assert len(sheet.cells) == 0
    assert len(sheet.cells) == 2

    # sheet = ipysheet.sheet(rows=3, columns=4)
    # range1, cells = ipysheet.cell_range([[0, 1], [2, 3]], return_cells=True)
    # assert range1.value == [[0, 1], [2, 3]]

    # sheet = ipysheet.sheet(rows=3, columns=4)
    # range1, cells = ipysheet.cell_range([[0, 1], [2, 3]], return_cells=True)
    # cells[1][0].value = 99
    # assert range1.value == [[0, 1], [99, 3]]
    # print('now we reset it')
    # range1.value = [[0, 1], [2, 8]]
    # print('now we reset it...')
    # assert cells[1][0].value == 2

    # sheet = ipysheet.sheet(rows=3, columns=4)
    # range2, cells = ipysheet.cell_range([[0, 1], [2, 3]], return_cells=True, transpose=True)
    # cells[1][0].value = 99
    # assert range2.value == [[0, 99], [1, 3]]
    # range2.value = [[0, 1], [2, 3]]
    # assert cells[1][0].value == 2

    # sheet = ipysheet.sheet(rows=2, columns=1)
    # range2 = ipysheet.cell_range([[0, 1]], transpose=True)
    # #range2.

    # sheet = ipysheet.sheet(rows=1, columns=2)
    # range2 = ipysheet.cell_range([[0], [2]], transpose=True)


def test_cell_values():
    cell = ipysheet.cell(0, 0, value=True)
    assert cell.value is True
    assert cell.type == 'checkbox'

    cell = ipysheet.cell(0, 0, value=1.2)
    assert cell.value == 1.2
    assert cell.type == 'numeric'
    cell = ipysheet.cell(0, 0, value=1)
    assert cell.value == 1
    assert cell.type == 'numeric'

    cell = ipysheet.Cell(value='1.2')
    assert cell.value == '1.2'
    assert cell.type is None

    cell = ipysheet.row(0, [True, False])
    assert cell.value == [True, False]
    assert cell.type == 'checkbox'

    cell = ipysheet.row(0, [0, 1.2])
    assert cell.value == [0, 1.2]
    assert cell.type == 'numeric'

    cell = ipysheet.row(0, [0, 1])
    assert cell.value == [0, 1]
    assert cell.type == 'numeric'

    cell = ipysheet.row(0, ['a', 'b'])
    assert cell.value == ['a', 'b']
    assert cell.type == 'text'

    cell = ipysheet.row(0, [True, 0])
    assert cell.type == 'numeric'

    cell = ipysheet.row(0, [True, 'bla'])
    assert cell.type is None

    cell = ipysheet.cell(0, 0, choice=['a', 'b'])
    assert cell.type == 'dropdown'


def test_cell_style():
    cell = ipysheet.cell(0, 0, color='red')
    assert cell.style['color'] == 'red'
    cell = ipysheet.cell(0, 0, background_color='blue')
    assert cell.style['backgroundColor'] == 'blue'
    cell = ipysheet.cell(0, 0, font_style='nice')
    assert cell.style['fontStyle'] == 'nice'
    cell = ipysheet.cell(0, 0, font_weight='bold')
    assert cell.style['fontWeight'] == 'bold'


def test_cell_range_style():
    values = [[1]]
    cell = ipysheet.cell_range(values, color='red')
    assert cell.style['color'] == 'red'
    cell = ipysheet.cell_range(values, background_color='blue')
    assert cell.style['backgroundColor'] == 'blue'
    cell = ipysheet.cell_range(values, font_style='nice')
    assert cell.style['fontStyle'] == 'nice'
    cell = ipysheet.cell_range(values, font_weight='bold')
    assert cell.style['fontWeight'] == 'bold'


def test_cell_label():
    sheet = ipysheet.sheet()
    ipysheet.cell(0, 1, label_left='hi')
    assert sheet.cells[-1].value == 'hi'
    with pytest.raises(IndexError):
        ipysheet.cell(0, 0, label_left='hi')


def test_renderer():
    ipysheet.sheet()
    renderer = ipysheet.renderer('code', 'name')
    assert renderer.code == 'code'
    assert renderer.name == 'name'

    def somefunction(x):
        pass

    def f(x):
        somefunction(x)

    f(1)  # for coverage

    renderer = ipysheet.renderer(f, 'name2')
    assert "somefunction" in renderer.code
    assert renderer.name == 'name2'


def _format_date(date):
    import pandas as pd

    return pd.to_datetime(str(date)).strftime('%Y/%m/%d')


def test_to_dataframe():
    sheet = ipysheet.sheet(rows=5, columns=4)
    ipysheet.cell(0, 0, value=True)
    ipysheet.row(1, value=[2, 34, 543, 23])
    ipysheet.column(3, value=[1.2, 1.3, 1.4, 1.5, 1.6])

    df = ipysheet.to_dataframe(sheet)
    assert np.all(df['A'].tolist() == [True,   2, None, None, None])
    assert np.all(df['B'].tolist() == [None,  34, None, None, None])
    assert np.all(df['C'].tolist() == [None, 543, None, None, None])
    assert np.all(df['D'].tolist() == [1.2,  1.3,  1.4,  1.5,  1.6])

    sheet = ipysheet.sheet(rows=4, columns=4, column_headers=['c0', 'c1', 'c2', 'c3'], row_headers=['r0', 'r1', 'r2', 'r3'])
    ipysheet.cell_range(
        [
            [2, 34, 543, 23],
            [1,  1,   1,  1],
            [2,  2, 222, 22],
            [2,  0, 111, 11],
        ],
        row_start=0, column_start=0,
        transpose=True
    )

    df = ipysheet.to_dataframe(sheet)
    assert np.all(df['c0'].tolist() == [2, 34, 543, 23])
    assert np.all(df['c1'].tolist() == [1,  1,   1,  1])
    assert np.all(df['c2'].tolist() == [2,  2, 222, 22])
    assert np.all(df['c3'].tolist() == [2,  0, 111, 11])

    sheet = ipysheet.sheet(rows=4, columns=4, column_headers=['t0', 't1', 't2', 't3'])
    ipysheet.cell_range(
        [
            [2, 34, 543, 23],
            [1,  1,   1,  1],
            [2,  2, 222, 22],
            [2,  0, 111, 11],
        ],
        row_start=0, column_start=0,
        transpose=False
    )

    df = ipysheet.to_dataframe(sheet)
    assert np.all(df['t0'].tolist() == [2,   1,   2,   2])
    assert np.all(df['t1'].tolist() == [34,  1,   2,   0])
    assert np.all(df['t2'].tolist() == [543, 1, 222, 111])
    assert np.all(df['t3'].tolist() == [23,  1,  22,  11])

    sheet = ipysheet.sheet(rows=0, columns=0)

    df = ipysheet.to_dataframe(sheet)
    assert np.all(df == pd.DataFrame())

    sheet = ipysheet.sheet(rows=4, columns=1)
    ipysheet.column(0, ['2019/02/28', '2019/02/27', '2019/02/26', '2019/02/25'], type='date')

    df = ipysheet.to_dataframe(sheet)
    assert [_format_date(x) for x in df['A'].tolist()] == ['2019/02/28', '2019/02/27', '2019/02/26', '2019/02/25']


def test_from_dataframe():
    df = pd.DataFrame({
        'A': 1.,
        'B': pd.Timestamp('20130102'),
        'C': pd.Series(1, index=list(range(4)), dtype='float32'),
        'D': np.array([False, True, False, False], dtype='bool'),
        'S': pd.Categorical(["test", "train", "test", "train"]),
        'T': 'foo'})

    sheet = ipysheet.from_dataframe(df)
    assert len(sheet.cells) == 6
    assert sheet.column_headers == ['A', 'B', 'C', 'D', 'S', 'T']
    assert sheet.cells[0].value == [1., 1., 1., 1.]
    assert sheet.cells[0].type == 'numeric'
    assert sheet.cells[1].value == ['2013/01/02', '2013/01/02', '2013/01/02', '2013/01/02']
    assert sheet.cells[1].type == 'date'
    assert sheet.cells[2].value == [1., 1., 1., 1.]
    assert sheet.cells[2].type == 'numeric'
    assert sheet.cells[3].value == [False, True, False, False]
    assert sheet.cells[3].type == 'checkbox'
    assert sheet.cells[4].value == ['test', 'train', 'test', 'train']
    assert sheet.cells[4].type == 'text'
    assert sheet.cells[5].value == ['foo', 'foo', 'foo', 'foo']
    assert sheet.cells[5].type == 'text'


def test_to_array():
    sheet = ipysheet.sheet(rows=5, columns=4)
    ipysheet.cell(0, 0, value=True)
    ipysheet.row(1, value=[2, 34, 543, 23])
    ipysheet.column(3, value=[1.2, 1.3, 1.4, 1.5, 1.6])

    arr = ipysheet.to_array(sheet)
    expected = np.array([
        [True, None, None, 1.2],
        [2,      34,  543, 1.3],
        [None, None, None, 1.4],
        [None, None, None, 1.5],
        [None, None, None, 1.6]
    ])
    assert np.all(arr == expected)


def test_from_array():
    arr = np.random.randn(6, 10, 2)
    with pytest.raises(RuntimeError):
        ipysheet.from_array(arr)

    arr = np.random.randn(6, 10)
    sheet = ipysheet.from_array(arr)
    assert len(sheet.cells) == 1
    assert sheet.cells[0].type == 'numeric'
    assert sheet.cells[0].value is arr
    assert sheet.rows == 6
    assert sheet.columns == 10

    arr = np.array([True, False, True])
    sheet = ipysheet.from_array(arr)
    assert len(sheet.cells) == 1
    assert sheet.cells[0].type == 'checkbox'
    assert sheet.cells[0].value is arr
    assert sheet.rows == 3
    assert sheet.columns == 1


def test_value_types_serialize(kernel):
    # test scalars, list, ndarray and pandas series
    # this test duplicates a bit from test_cell_range and test_row_and_column
    x = np.arange(3)
    y = x**2
    xr = x[::-1]
    x_list = x.tolist()
    xr_list = xr.tolist()
    matrix = np.array([x, y]).T
    matrix_list = matrix.tolist()
    matrix_r = matrix[::, ::-1]
    matrix_list_r = matrix_r.tolist()
    df = pd.DataFrame({'x': x})
    df['y'] = y
    assert not isinstance(df.x, np.ndarray)

    cell_scalar = ipysheet.Cell()
    cell_vector = ipysheet.Cell(row_start=0, row_end=2, squeeze_row=False)
    cell_matrix = ipysheet.Cell(row_start=0, row_end=2, column_start=0, column_end=1,
                                squeeze_row=False, squeeze_column=False)
    cell_scalar.comm.kernel = kernel
    cell_vector.comm.kernel = kernel
    cell_matrix.comm.kernel = kernel

    # scalar

    cell_scalar.value = 1
    assert cell_scalar.value == 1

    cell_scalar.value = 1.1
    assert cell_scalar.value == 1.1

    cell_scalar.value = True
    assert cell_scalar.value is True

    cell_scalar.value = 'voila'
    assert cell_scalar.value == 'voila'

    cell_scalar.value = np.int64(1)
    assert cell_scalar.value == 1

    # vector
    cell_vector.value = x_list
    assert cell_vector.value == x_list

    cell_vector.set_state({'value': xr_list})
    assert cell_vector.value == xr_list

    # vector+numpy
    cell_vector.value = x
    assert isinstance(cell_vector.value, np.ndarray)
    assert cell_vector.value.tolist() == x.tolist()

    # we'd like it to stay a ndarray
    cell_vector.set_state({'value': xr_list})
    assert isinstance(cell_vector.value, np.ndarray)
    assert cell_vector.value.tolist() == xr_list

    # vector+series
    cell_vector.value = df.x
    assert cell_vector.value.tolist() == df.x.tolist()
    assert isinstance(cell_vector.value, pd.Series)

    # we'd like it to stay a series
    cell_vector.set_state({'value': x_list})
    assert isinstance(cell_vector.value, pd.Series)
    assert cell_vector.value.tolist() == x_list

    with pytest.raises(ValueError):
        cell_vector.value = 1

    # matrix
    cell_matrix.value = matrix_list
    assert cell_matrix.value == matrix_list

    # matrix+numpy
    cell_matrix.value = matrix
    assert isinstance(cell_matrix.value, np.ndarray)
    assert cell_matrix.value.tolist() == matrix_list

    # we'd like it to stay a ndarray
    cell_matrix.set_state({'value': matrix_list_r})
    assert isinstance(cell_matrix.value, np.ndarray)
    assert cell_matrix.value.tolist() == matrix_list_r

    # matrix+dataframe
    cell_matrix.value = df  # pandas to_numpy->tolist() gives the transposed result
    assert adapt_value(cell_matrix.value) == matrix_list
    assert isinstance(cell_matrix.value, pd.DataFrame)

    # we'd like it to stay a dataframe
    cell_matrix.set_state({'value': matrix_list})
    assert isinstance(cell_matrix.value, pd.DataFrame)
    assert adapt_value(cell_matrix.value) == matrix_list

    with pytest.raises(ValueError):
        cell_matrix.value = 1
    with pytest.raises(ValueError):
        cell_matrix.value = x

    # make sure we can still set the widgets, and they serialize

    button = widgets.Button()
    slider = widgets.FloatSlider()
    cell_scalar.value = button

    cell_vector.value = [slider, button, button]
    cell_vector.set_state(
        {'value': ['IPY_MODEL_' + button.model_id, 'IPY_MODEL_' + slider.model_id, 'IPY_MODEL_' + slider.model_id]})
    assert cell_vector.value == [button, slider, slider]

    # even when originally a ndarray
    cell_vector.value = x
    cell_vector.set_state(
        {'value': ['IPY_MODEL_' + button.model_id, 'IPY_MODEL_' + button.model_id, 'IPY_MODEL_' + slider.model_id]})
    assert cell_vector.value == [button, button, slider]

    # or series
    # TODO: this code path fails, we can consider it not supported
    #   * you cannot change a cell's value from the frontend from to a different type when it's a pandas series
    # cell_vector.value = df.x
    # cell_vector.set_state(
    #     {'value': ['IPY_MODEL_' + slider.model_id, 'IPY_MODEL_' + button.model_id, 'IPY_MODEL_' + slider.model_id]})
    # assert cell_vector.value == [slider, button, slider]
