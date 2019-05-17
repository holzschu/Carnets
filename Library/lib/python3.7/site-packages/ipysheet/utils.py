def transpose(list_of_lists):
    return [list(k) for k in zip(*list_of_lists)]


def adapt_value(value):
    # a pandas dataframe will hit this path first
    if hasattr(value, "to_numpy"):
        value = value.to_numpy()
    # a pandas series will hit this path
    if hasattr(value, "values"):
        import numpy as np
        value = np.array(value.values)
    # numpy arrays will hit this path
    if hasattr(value, "tolist"):
        value = value.tolist()
    return value


def extract_cell_data(cell, data):
    for row in range(cell.row_start, cell.row_end + 1):
        for col in range(cell.column_start, cell.column_end + 1):
            value = cell.value
            if cell.transpose:
                if not cell.squeeze_column:
                    value = value[col]
                if not cell.squeeze_row:
                    value = value[row]
            else:
                if not cell.squeeze_row:
                    value = value[row]
                if not cell.squeeze_column:
                    value = value[col]

            data[row][col]['value'] = value
            data[row][col]['options']['type'] = cell.type


def extract_data(sheet):
    data = []
    for _ in range(sheet.rows):
        data.append([
            {'value': None, 'options': {'type': type(None)}}
            for _ in range(sheet.columns)
        ])

    for cell in sheet.cells:
        extract_cell_data(cell, data)

    return data
