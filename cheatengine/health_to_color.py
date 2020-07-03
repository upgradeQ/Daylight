import obspython as obs

PATH_TO_VALUE_FILE = "path/to/output.txt"


class Example:
    def __init__(self, source_name=None):
        self.source_name = source_name
        self.max_value = 100  # max HP
        self.lock = True
        self.is_running = False
        self.last_value = 1

    def update_color(self):
        source = obs.obs_get_source_by_name(self.source_name)
        scroll = obs.obs_source_get_filter_by_name(source, "py_color")
        filter_settings = obs.obs_source_get_settings(scroll)

        value = self.value
        if value:
            self.last_value = value
        if value == 0:
            value = self.last_value
        value = 50 - value

        obs.obs_data_set_int(filter_settings, "opacity", value)
        obs.obs_source_update(scroll, filter_settings)

        obs.obs_data_release(filter_settings)
        obs.obs_source_release(source)
        obs.obs_source_release(scroll)

    @property
    def value(self):
        """ 50 opacity = 100 %"""
        opacity_base = 50
        with open(PATH_TO_VALUE_FILE) as f:
            v = f.read()
        if v != "??":
            v = int(v)
            r = (v+1) / self.max_value
            result =  round(opacity_base * r) 
            return result 
        return 0

    def ticker(self):
        print('tick')
        if not self.lock:
            obs.remove_current_callback()

        self.update_color()

    def toggle(self):
        self.is_running = not self.is_running
        if self.lock and not self.is_running:
            obs.timer_add(self.ticker, 200)
            self.is_running = True

    def run(self):
        print(self.lock)
        self.lock = not self.lock


eg = Example()  # class created ,obs part starts


def start_pressed(props, prop):
    eg.run()


def script_defaults(settings):
    obs.obs_data_set_default_int(settings, "max_value", 100)


def script_update(settings):
    eg.source_name = obs.obs_data_get_string(settings, "source")
    eg.max_value = obs.obs_data_get_int(settings, "max_value")


def script_properties():  # ui
    props = obs.obs_properties_create()
    obs.obs_properties_add_int(props, "max_value", "Max value", 1, 1_000_000, 1)
    p = obs.obs_properties_add_list(
        props,
        "source",
        "Color Source",
        obs.OBS_COMBO_TYPE_EDITABLE,
        obs.OBS_COMBO_FORMAT_STRING,
    )
    sources = obs.obs_enum_sources()
    if sources is not None:
        for source in sources:
            source_id = obs.obs_source_get_unversioned_id(source)
            name = obs.obs_source_get_name(source)
            obs.obs_property_list_add_string(p, name, name)

        obs.source_list_release(sources)
    obs.obs_properties_add_button(props, "button", "Start", start_pressed)
    obs.obs_properties_add_button(
        props, "button1", "Stop", lambda *props: eg.toggle()
    )
    return props
