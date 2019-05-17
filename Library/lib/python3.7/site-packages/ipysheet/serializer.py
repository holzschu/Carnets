import ipywidgets as widgets
from .utils import adapt_value


def create_value_serializer(name):
    """Create a serializer that support widgets, and anything json accepts while preserving type"""
    def value_to_json(value, widget):
        # first take out all widgets
        value = widgets.widget_serialization['to_json'](value, widget)
        return adapt_value(value)

    def json_to_value(data, widget):
        # first put pack widgets in
        value = widgets.widget_serialization['from_json'](data, widget)
        original = getattr(widget, name)
        if hasattr(original, 'copy'):  # this path will try to preserve the type
            # numpy arrays and dataframs follow this path
            try:
                copy = original.copy()
                copy[:] = value
                value = copy
            except TypeError:
                pass  # give up for instance when we set Widgets into a float array
        return value

    return {
        'to_json': value_to_json,
        'from_json': json_to_value
    }
