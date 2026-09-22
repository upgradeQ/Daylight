local ffi = require("ffi")
local bit = require("bit")
local fnew, cast = ffi.new, ffi.cast
local _OR = bit.bor

local S = obslua

local M = {}

local function try_load_library(alias, name)
  local ok
  ok, _G[alias] = pcall(ffi.load, name)
  if not ok then
    print(("WARNING:%s:Has failed to load, %s is nil"):format(name, alias))
  end
  return ok
end

try_load_library("obsffi", "obs")
try_load_library("user32", "user32")
try_load_library("dcompdll", "dcomp")
try_load_library("kernel32", "kernel32")

local cdef_done = pcall(
  ffi.cdef,
  [[
typedef struct { uint32_t Data1; uint16_t Data2; uint16_t Data3; uint8_t Data4[8]; } GUID_T;

struct comobj { void** lpVtbl; };

typedef struct {
  void* hwnd;
  uint32_t message;
  uintptr_t wParam;
  intptr_t lParam;
  uint32_t time;
  int32_t pt_x;
  int32_t pt_y;
} MSG_T;

typedef struct { uint32_t Count; uint32_t Quality; } DXGI_SAMPLE_DESC_T;

typedef struct {
  uint32_t Width;
  uint32_t Height;
  uint32_t Format;
  int32_t  Stereo;
  DXGI_SAMPLE_DESC_T SampleDesc;
  uint32_t BufferUsage;
  uint32_t BufferCount;
  uint32_t Scaling;
  uint32_t SwapEffect;
  uint32_t AlphaMode;
  uint32_t Flags;
} DXGI_SWAP_CHAIN_DESC1_T;

void* CreateWindowExA(uint32_t dwExStyle, const char* lpClassName, const char* lpWindowName,
  uint32_t dwStyle, int x, int y, int nWidth, int nHeight,
  void* hWndParent, void* hMenu, void* hInstance, void* lpParam);
int DestroyWindow(void* hWnd);
int ShowWindow(void* hWnd, int nCmdShow);
int SetWindowPos(void* hWnd, void* hWndInsertAfter, int X, int Y, int cx, int cy, uint32_t uFlags);
int IsWindowVisible(void* hWnd);
intptr_t GetWindowLongPtrA(void* hWnd, int nIndex);
intptr_t SetWindowLongPtrA(void* hWnd, int nIndex, intptr_t dwNewLong);
int PeekMessageA(void* lpMsg, void* hWnd, uint32_t wMsgFilterMin, uint32_t wMsgFilterMax, uint32_t wRemoveMsg);
int TranslateMessage(const void* lpMsg);
intptr_t DispatchMessageA(const void* lpMsg);
int GetSystemMetrics(int nIndex);
uint32_t GetLastError(void);
int SetWindowDisplayAffinity(void* hWnd, uint32_t dwAffinity);
void* GetForegroundWindow(void);
uint32_t GetWindowThreadProcessId(void* hWnd, uint32_t* lpdwProcessId);
int IsIconic(void* hWnd);

uint32_t GetCurrentProcessId(void);
uint64_t GetTickCount64(void);

typedef struct { int32_t x, y; } DUP_POINT_T;
typedef struct {
  DUP_POINT_T Position;
  int32_t Visible;
} DXGI_OUTDUPL_POINTER_POSITION_T;
typedef struct {
  int64_t LastPresentTime;
  int64_t LastMouseUpdateTime;
  uint32_t AccumulatedFrames;
  int32_t RectsCoalesced;
  int32_t ProtectedContentMaskedOut;
  DXGI_OUTDUPL_POINTER_POSITION_T PointerPosition;
  uint32_t TotalMetadataBufferSize;
  uint32_t PointerShapeBufferSize;
} DXGI_OUTDUPL_FRAME_INFO_T;

int32_t DCompositionCreateDevice(void* dxgiDevice, const GUID_T* iid, void** dcompositionDevice);

struct gs_texture;
typedef struct gs_texture gs_texture_t;
struct gs_texture_render;
typedef struct gs_texture_render gs_texrender_t;

void *gs_get_device_obj(void);
void *gs_texture_get_obj(gs_texture_t *tex);
gs_texrender_t *gs_texrender_create(int format, int zsformat);
void gs_texrender_destroy(gs_texrender_t *texrender);
void gs_texrender_reset(gs_texrender_t *texrender);
bool gs_texrender_begin(gs_texrender_t *texrender, uint32_t width, uint32_t height);
void gs_texrender_end(gs_texrender_t *texrender);
gs_texture_t *gs_texrender_get_texture(gs_texrender_t *texrender);

struct gs_effect;
typedef struct gs_effect gs_effect_t;
struct gs_effect_param;
typedef struct gs_effect_param gs_eparam_t;

gs_effect_t *obs_get_base_effect(int effect);
gs_effect_t *gs_effect_create(const char *effect_string, const char *filename, char **error_string);
void gs_effect_destroy(gs_effect_t *effect);
gs_eparam_t *gs_effect_get_param_by_name(const gs_effect_t *effect, const char *name);
void gs_effect_set_texture(gs_eparam_t *param, gs_texture_t *val);
void gs_effect_set_float(gs_eparam_t *param, float val);
bool gs_effect_loop(gs_effect_t *effect, const char *name);
void gs_draw_sprite(gs_texture_t *tex, uint32_t flip, uint32_t width, uint32_t height);
]]
)

if not cdef_done then
  print("[overlay_share] ffi.cdef already registered, continuing")
end

local WS_POPUP = 0x80000000
local WS_EX_TRANSPARENT = 0x00000020
local WS_EX_TOPMOST = 0x00000008
local WS_EX_TOOLWINDOW = 0x00000080
local WS_EX_NOACTIVATE = 0x08000000
local WS_EX_LAYERED = 0x00080000
local SW_HIDE = 0
local SW_SHOWNOACTIVATE = 4
local SWP_NOACTIVATE = 0x0010
local SWP_SHOWWINDOW = 0x0040
local SWP_NOSIZE = 0x0001
local SWP_NOMOVE = 0x0002
local SWP_NOZORDER = 0x0004
local SWP_FRAMECHANGED = 0x0020
local GWL_EXSTYLE = -20
local HWND_TOPMOST = cast("void*", -1)
local PM_REMOVE = 0x0001
local SM_CXSCREEN = 0
local SM_CYSCREEN = 1

local DXGI_FORMAT_B8G8R8A8_UNORM = 87
local DXGI_USAGE_RENDER_TARGET_OUTPUT = 0x00000020
local DXGI_SCALING_STRETCH = 0
local DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL = 3
local DXGI_ALPHA_MODE_PREMULTIPLIED = 1

local VT_RELEASE = 2
local VT_D3D11DEVICE_QUERYINTERFACE = 0
local VT_D3D11DEVICE_GETIMMEDIATECONTEXT = 40
local VT_D3D11CONTEXT_COPYRESOURCE = 47
local VT_DXGIOBJECT_GETPARENT = 6
local VT_DXGIDEVICE_GETADAPTER = 7
local VT_DXGIFACTORY2_CREATESWAPCHAINFORCOMPOSITION = 24
local VT_DXGISWAPCHAIN_PRESENT = 8
local VT_DXGISWAPCHAIN_GETBUFFER = 9
local VT_DCOMPDEVICE_COMMIT = 3
local VT_DCOMPDEVICE_CREATETARGETFORHWND = 6
local VT_DCOMPDEVICE_CREATEVISUAL = 7
local VT_DCOMPTARGET_SETROOT = 3
local VT_DCOMPVISUAL_SETCONTENT = 15
local VT_D3D11CONTEXT_VSSETSHADERRESOURCES = 25
local VT_D3D11CONTEXT_PSGETSHADERRESOURCES = 73

local VT_DXGIADAPTER_ENUMOUTPUTS = 7
local VT_DXGIOUTPUT1_DUPLICATEOUTPUT = 22
local VT_DXGIOUTPUTDUP_ACQUIRENEXTFRAME = 8
local VT_DXGIOUTPUTDUP_RELEASEFRAME = 14

local WDA_EXCLUDEFROMCAPTURE = 0x00000011
local DXGI_ERROR_WAIT_TIMEOUT = 0x887A0027
local DXGI_ERROR_ACCESS_LOST = 0x887A0026

local function make_guid(d1, d2, d3, b0, b1, b2, b3, b4, b5, b6, b7)
  local g = fnew("GUID_T")
  g.Data1, g.Data2, g.Data3 = d1, d2, d3
  g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3] = b0, b1, b2, b3
  g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7] = b4, b5, b6, b7
  return g
end

local IID_IDXGIDevice = make_guid(0x54ec77fa, 0x1377, 0x44e6, 0x8c, 0x32, 0x88, 0xfd, 0x5f, 0x44, 0xc8, 0x4c)
local IID_IDXGIFactory2 = make_guid(0x50c83a1c, 0xe072, 0x4c48, 0x87, 0xb0, 0x36, 0x30, 0xfa, 0x36, 0xa6, 0xd0)
local IID_ID3D11Texture2D = make_guid(0x6f15aaf2, 0xd208, 0x4e89, 0x9a, 0xb4, 0x48, 0x95, 0x35, 0xd3, 0x4f, 0x9c)
local IID_IDCompositionDevice = make_guid(0xc37ea93a, 0xe7aa, 0x450d, 0xb1, 0x6f, 0x97, 0x46, 0xcb, 0x04, 0x07, 0xf3)
local IID_IDXGIOutput1 = make_guid(0x00cddea8, 0x939b, 0x4b83, 0xa3, 0x40, 0xa6, 0x85, 0x22, 0x66, 0x66, 0xcc)

local msg_buf = fnew("MSG_T")
local out1 = fnew("void*[1]")

local typeof = ffi.typeof
local PCOMOBJ = typeof("struct comobj*")
local PINT32 = typeof("int32_t")
local PUINT32 = typeof("uint32_t")

local FN = {
  release = typeof("uint32_t(__stdcall*)(void*)"),
  get_ctx = typeof("void(__stdcall*)(void*, void**)"),
  qi = typeof("int32_t(__stdcall*)(void*, const GUID_T*, void**)"),
  get_adapter = typeof("int32_t(__stdcall*)(void*, void**)"),
  get_parent = typeof("int32_t(__stdcall*)(void*, const GUID_T*, void**)"),
  create_sc = typeof("int32_t(__stdcall*)(void*, void*, const DXGI_SWAP_CHAIN_DESC1_T*, void*, void**)"),
  create_target = typeof("int32_t(__stdcall*)(void*, void*, int32_t, void**)"),
  create_visual = typeof("int32_t(__stdcall*)(void*, void**)"),
  set_content = typeof("int32_t(__stdcall*)(void*, void*)"),
  set_root = typeof("int32_t(__stdcall*)(void*, void*)"),
  commit = typeof("int32_t(__stdcall*)(void*)"),
  get_buffer = typeof("int32_t(__stdcall*)(void*, uint32_t, const GUID_T*, void**)"),
  copy_resource = typeof("void(__stdcall*)(void*, void*, void*)"),
  present = typeof("int32_t(__stdcall*)(void*, uint32_t, uint32_t)"),
  srv = typeof("void(__stdcall*)(void*, uint32_t, uint32_t, void**)"),
  enum_outputs = typeof("int32_t(__stdcall*)(void*, uint32_t, void**)"),
  duplicate_output = typeof("int32_t(__stdcall*)(void*, void*, void**)"),
  acquire_frame = typeof("int32_t(__stdcall*)(void*, uint32_t, DXGI_OUTDUPL_FRAME_INFO_T*, void**)"),
  release_frame = typeof("int32_t(__stdcall*)(void*)"),
}

local dup_info = fnew("DXGI_OUTDUPL_FRAME_INFO_T")
local pid_buf = fnew("uint32_t[1]")
local host_pid = kernel32 and tonumber(kernel32.GetCurrentProcessId()) or 0

local function vt(iface, index, ctype)
  return cast(ctype, cast(PCOMOBJ, iface).lpVtbl[index])
end

local function com_release(iface)
  if iface ~= nil then
    vt(iface, VT_RELEASE, FN.release)(iface)
  end
end

local function failed(hr)
  return cast(PINT32, hr) < 0
end

local function hrstr(hr)
  return string.format("0x%08X", tonumber(cast(PUINT32, hr)))
end

local Overlay = {}
Overlay.__index = Overlay

M.DESKTOP_MODES = {
  { "off (effect only, transparent)", "off" },
  { "normal (source over)", "normal" },
  { "additive", "add" },
  { "screen", "screen" },
  { "lighten (max)", "lighten" },
  { "darken (min)", "darken" },
  { "multiply", "multiply" },
  { "overlay", "overlay" },
  { "soft light", "softlight" },
  { "colour dodge", "dodge" },
  { "difference", "difference" },
}

-- must match the branch order in PSComposite
local DESKTOP_MODE_INDEX = {
  normal = 0,
  add = 1,
  screen = 2,
  lighten = 3,
  darken = 4,
  multiply = 5,
  overlay = 6,
  softlight = 7,
  dodge = 8,
  difference = 9,
}

M.DEFAULT_DESKTOP_MODE = "off"
M.DEFAULT_DESKTOP_OPACITY = 1.0
M.DEFAULT_DESKTOP_GAIN = 1.0
M.DEFAULT_DESKTOP_DIM = 0.0

function M.add_desktop_mode_list(props, id, label)
  local list = S.obs_properties_add_list(
    props,
    id or "_desktop",
    label or "blend with desktop",
    S.OBS_COMBO_TYPE_LIST,
    S.OBS_COMBO_FORMAT_STRING
  )
  for _, entry in ipairs(M.DESKTOP_MODES) do
    S.obs_property_list_add_string(list, entry[1], entry[2])
  end
  S.obs_property_set_long_description(
    list,
    "Costs a full-screen desktop capture and composite every frame, whatever the effect covers."
      .. " Leave it OFF unless you need a mode DWM cannot do - additive, screen, multiply and the"
      .. " rest.\n 'Normal (source over)' is exactly what DWM already does for a transparent window,"
      .. " so off + overlay opacity gives the same picture for far less work."
  )
  return list
end

function M.read_desktop_mode(settings, id)
  local mode = S.obs_data_get_string(settings, id or "_desktop")
  if mode == nil or (mode ~= "off" and DESKTOP_MODE_INDEX[mode] == nil) then
    return M.DEFAULT_DESKTOP_MODE
  end
  return mode
end

function M.add_desktop_opacity_slider(props, id, label)
  local p = S.obs_properties_add_float_slider(props, id or "_ovopacity", label or "overlay opacity", 0.0, 1.0, 0.01)
  S.obs_property_set_long_description(
    p,
    "Fades the whole overlay. Works with 'blend with desktop' off, where the window is"
      .. " genuinely semi-transparent and DWM does the blending for free."
  )
  return p
end

function M.add_desktop_gain_slider(props, id, label)
  return S.obs_properties_add_float_slider(props, id or "_ovgain", label or "overlay brightness", 0.0, 2.0, 0.01)
end

function M.add_desktop_dim_slider(props, id, label)
  local p =
    S.obs_properties_add_float_slider(props, id or "_ovdim", label or "dim desktop under effect", 0.0, 1.0, 0.01)
  S.obs_property_set_long_description(p, "Needs 'blend with desktop'. Without a backdrop there is nothing to dim.")
  return p
end

function M.read_desktop_opacity(settings, id)
  return S.obs_data_get_double(settings, id or "_ovopacity")
end

function M.read_desktop_gain(settings, id)
  return S.obs_data_get_double(settings, id or "_ovgain")
end

function M.read_desktop_dim(settings, id)
  return S.obs_data_get_double(settings, id or "_ovdim")
end

function Overlay:set_desktop_levels(opacity, gain, dim)
  self.desk_opacity = opacity or M.DEFAULT_DESKTOP_OPACITY
  self.desk_gain = gain or M.DEFAULT_DESKTOP_GAIN
  self.desk_dim = dim or M.DEFAULT_DESKTOP_DIM
end

M.DEFAULT_FOCUS_HIDE = true
M.DEFAULT_FOCUS_DELAY = 3

function M.add_position_sliders(props, idx, idy)
  S.obs_properties_add_int_slider(props, idx or "_ovx", "window offset x (px)", -8000, 8000, 1)
  S.obs_properties_add_int_slider(props, idy or "_ovy", "window offset y (px)", -8000, 8000, 1)
end

function M.read_position(settings, idx, idy)
  return S.obs_data_get_int(settings, idx or "_ovx"), S.obs_data_get_int(settings, idy or "_ovy")
end

function M.add_focus_hide_toggle(props, id, label)
  return S.obs_properties_add_bool(props, id or "_ovfocus", label or "hide overlay while OBS is focused")
end

function M.add_focus_delay_slider(props, id, label)
  return S.obs_properties_add_int_slider(props, id or "_ovdelay", label or "seconds before overlay returns", 0, 30, 1)
end

function M.read_focus_hide(settings, id)
  return S.obs_data_get_bool(settings, id or "_ovfocus")
end

function M.read_focus_delay(settings, id)
  return S.obs_data_get_int(settings, id or "_ovdelay")
end

function Overlay:set_focus_hide(on, delay)
  self.focus_hide = on and true or false
  if delay ~= nil then
    self.focus_delay = math.max(0, delay)
  end
end

local function now_ms()
  if kernel32 == nil then
    return 0
  end
  return tonumber(kernel32.GetTickCount64())
end

function Overlay:host_focused()
  if user32 == nil or host_pid == 0 then
    return false
  end
  local fg = user32.GetForegroundWindow()
  if fg == nil then
    return false
  end
  if self.hwnd ~= nil and fg == self.hwnd then
    return false
  end
  pid_buf[0] = 0
  user32.GetWindowThreadProcessId(fg, pid_buf)
  if pid_buf[0] ~= host_pid then
    return false
  end
  self.host_hwnd = fg
  return true
end

function Overlay:update_suspend()
  if not self.focus_hide then
    self.suspended = false
    return
  end
  if self:host_focused() then
    self.suspended = true
    self.resume_at = now_ms() + self.focus_delay * 1000
    return
  end
  if not self.suspended then
    return
  end
  if self.host_hwnd ~= nil and user32.IsIconic(self.host_hwnd) ~= 0 then
    self.suspended = false
    return
  end
  if now_ms() >= self.resume_at then
    self.suspended = false
  end
end

function Overlay:set_window_shown(v)
  if self.hwnd == nil or self.window_shown == v then
    return
  end
  self.window_shown = v
  if v then
    user32.ShowWindow(self.hwnd, SW_SHOWNOACTIVATE)
    user32.SetWindowPos(
      self.hwnd,
      HWND_TOPMOST,
      0,
      0,
      0,
      0,
      _OR(SWP_NOMOVE, SWP_NOSIZE, SWP_NOACTIVATE, SWP_SHOWWINDOW)
    )
  else
    user32.ShowWindow(self.hwnd, SW_HIDE)
  end
end

function Overlay:set_desktop_mode(mode)
  if self.desktop_mode == mode then
    return
  end
  self.desktop_mode = mode
  self.rebuild_wanted = true
end

function Overlay:dup_teardown()
  if self.dup ~= nil and self.dup_held then
    vt(self.dup, VT_DXGIOUTPUTDUP_RELEASEFRAME, FN.release_frame)(self.dup)
  end
  self.dup_held = false
  com_release(self.dup)
  self.dup = nil
  if self.desk_tr ~= nil then
    obsffi.gs_texrender_destroy(self.desk_tr)
    self.desk_tr = nil
  end
  self.desk_tex = nil
  self.desk_obj = nil
  self.have_desk = false
end

function Overlay:dup_init(adapter, w, h)
  self:dup_teardown()

  out1[0] = nil
  local enum_outputs = vt(adapter, VT_DXGIADAPTER_ENUMOUTPUTS, FN.enum_outputs)
  local hr = enum_outputs(adapter, 0, out1)
  if failed(hr) or out1[0] == nil then
    self.dup_status = "EnumOutputs failed hr=" .. hrstr(hr)
    return false
  end
  local output = out1[0]

  out1[0] = nil
  local qi = vt(output, VT_D3D11DEVICE_QUERYINTERFACE, FN.qi)
  hr = qi(output, IID_IDXGIOutput1, out1)
  com_release(output)
  if failed(hr) or out1[0] == nil then
    self.dup_status = "QueryInterface(IDXGIOutput1) failed hr=" .. hrstr(hr)
    return false
  end
  local output1 = out1[0]

  out1[0] = nil
  local dup_out = vt(output1, VT_DXGIOUTPUT1_DUPLICATEOUTPUT, FN.duplicate_output)
  hr = dup_out(output1, self.device, out1)
  com_release(output1)
  if failed(hr) or out1[0] == nil then
    self.dup_status = "DuplicateOutput failed hr=" .. hrstr(hr)
    return false
  end
  self.dup = out1[0]

  self.desk_tr = obsffi.gs_texrender_create(S.GS_BGRA, S.GS_ZS_NONE)
  if self.desk_tr == nil then
    self.dup_status = "desktop texrender creation failed"
    self:dup_teardown()
    return false
  end
  obsffi.gs_texrender_reset(self.desk_tr)
  if not obsffi.gs_texrender_begin(self.desk_tr, w, h) then
    self.dup_status = ("desktop texrender begin failed at %dx%d"):format(w, h)
    self:dup_teardown()
    return false
  end
  obsffi.gs_texrender_end(self.desk_tr)

  self.desk_tex = obsffi.gs_texrender_get_texture(self.desk_tr)
  if self.desk_tex == nil then
    self.dup_status = "desktop texture is nil"
    self:dup_teardown()
    return false
  end
  self.desk_obj = obsffi.gs_texture_get_obj(self.desk_tex)
  if self.desk_obj == nil then
    self.dup_status = "gs_texture_get_obj on desktop texture returned nil"
    self:dup_teardown()
    return false
  end

  self.fn_acquire = vt(self.dup, VT_DXGIOUTPUTDUP_ACQUIRENEXTFRAME, FN.acquire_frame)
  self.fn_release_frame = vt(self.dup, VT_DXGIOUTPUTDUP_RELEASEFRAME, FN.release_frame)
  self.dup_status = ("duplicating %dx%d"):format(w, h)
  self:log("[+] desktop duplication " .. self.dup_status)
  return true
end

function Overlay:dup_capture()
  if self.dup == nil then
    return false
  end

  if self.dup_held then
    self.fn_release_frame(self.dup)
    self.dup_held = false
  end

  out1[0] = nil
  local hr = self.fn_acquire(self.dup, 0, dup_info, out1)
  if hr == DXGI_ERROR_WAIT_TIMEOUT then
    return true
  end
  if failed(hr) or out1[0] == nil then
    if hr == DXGI_ERROR_ACCESS_LOST then
      self.dup_status = "access lost, will rebuild"
      self.rebuild_wanted = true
    elseif self.last_dup_hr ~= hr then
      self.last_dup_hr = hr
      self.dup_status = "AcquireNextFrame failed hr=" .. hrstr(hr)
      self:log("[-] " .. self.dup_status)
    end
    return false
  end

  local resource = out1[0]
  self.dup_held = true

  if dup_info.LastPresentTime == 0 then
    self.fn_release_frame(self.dup)
    self.dup_held = false
    com_release(resource)
    self.pointer_only = self.pointer_only + 1
    return true
  end

  out1[0] = nil
  local qi = vt(resource, VT_D3D11DEVICE_QUERYINTERFACE, FN.qi)
  hr = qi(resource, IID_ID3D11Texture2D, out1)
  com_release(resource)
  if failed(hr) or out1[0] == nil then
    self.fn_release_frame(self.dup)
    self.dup_held = false
    return false
  end

  self.fn_copy(self.context, self.desk_obj, out1[0])
  com_release(out1[0])
  self.fn_release_frame(self.dup)
  self.dup_held = false
  self.captured = self.captured + 1
  self.have_desk = true
  return true
end

function M.new(name)
  local self = setmetatable({}, Overlay)
  self.name = name or "overlay"
  self.hwnd = nil
  self.device = nil
  self.context = nil
  self.swapchain = nil
  self.dcomp_device = nil
  self.dcomp_target = nil
  self.dcomp_visual = nil
  self.dup = nil
  self.dup_held = false
  self.desk_tr = nil
  self.desk_tex = nil
  self.desk_obj = nil
  self.desktop_mode = M.DEFAULT_DESKTOP_MODE
  self.dup_status = "not initialised"
  self.have_desk = false
  self.last_dup_hr = 0
  self.captured = 0
  self.pointer_only = 0
  self.desk_opacity = M.DEFAULT_DESKTOP_OPACITY
  self.desk_gain = M.DEFAULT_DESKTOP_GAIN
  self.desk_dim = M.DEFAULT_DESKTOP_DIM
  self.pos_x = 0
  self.pos_y = 0
  self.focus_hide = M.DEFAULT_FOCUS_HIDE
  self.focus_delay = M.DEFAULT_FOCUS_DELAY
  self.suspended = false
  self.resume_at = 0
  self.host_hwnd = nil
  self.window_shown = false
  self.rebuild_wanted = false
  self.texrender = nil
  self.width = 0
  self.height = 0
  self.ready = false
  self.enabled = false
  self.click_through = true
  self.disabled_by_error = false
  self.last_error = "none"
  self.last_present_hr = 0
  self.presented = 0
  return self
end

function Overlay:log(msg)
  print(("[%s] %s"):format(self.name, msg))
end

function Overlay:teardown()
  self.ready = false
  self.fn_get_buffer = nil
  self.fn_present = nil
  self.fn_copy = nil
  if self.texrender ~= nil then
    obsffi.gs_texrender_destroy(self.texrender)
    self.texrender = nil
  end
  if self.blit_effect ~= nil then
    obsffi.gs_effect_destroy(self.blit_effect)
    self.blit_effect = nil
    self.blit_params = nil
  end
  if self.comp_effect ~= nil then
    obsffi.gs_effect_destroy(self.comp_effect)
    self.comp_effect = nil
    self.comp_params = nil
  end
  self:dup_teardown()
  com_release(self.dcomp_visual)
  com_release(self.dcomp_target)
  com_release(self.dcomp_device)
  com_release(self.swapchain)
  com_release(self.context)
  self.dcomp_visual = nil
  self.dcomp_target = nil
  self.dcomp_device = nil
  self.swapchain = nil
  self.context = nil
  self.device = nil
  if self.hwnd ~= nil then
    user32.DestroyWindow(self.hwnd)
    self.hwnd = nil
  end
  self.window_shown = false
  self.suspended = false
  self.width, self.height = 0, 0
  self.presented = 0
end

function Overlay:fail(msg)
  self.last_error = msg
  self:log("[-] " .. msg)
  self:teardown()
  return false
end

function Overlay:exstyle()
  local ex = _OR(WS_EX_TOPMOST, WS_EX_TOOLWINDOW, WS_EX_NOACTIVATE)
  if self.click_through then
    ex = _OR(ex, WS_EX_TRANSPARENT, WS_EX_LAYERED)
  end
  return ex
end

function Overlay:window_origin(w, h)
  local sx = user32.GetSystemMetrics(SM_CXSCREEN)
  local sy = user32.GetSystemMetrics(SM_CYSCREEN)
  return math.floor((sx - w) / 2) + (self.pos_x or 0), math.floor((sy - h) / 2) + (self.pos_y or 0)
end

function Overlay:set_position(x, y)
  x = x or 0
  y = y or 0
  if self.pos_x == x and self.pos_y == y then
    return
  end
  self.pos_x, self.pos_y = x, y
  if self.hwnd == nil then
    return
  end
  local px, py = self:window_origin(self.width, self.height)
  user32.SetWindowPos(self.hwnd, HWND_TOPMOST, px, py, 0, 0, _OR(SWP_NOACTIVATE, SWP_NOSIZE))
end

function Overlay:create_window(w, h)
  local px, py = self:window_origin(w, h)
  local hwnd = user32.CreateWindowExA(self:exstyle(), "STATIC", self.name, WS_POPUP, px, py, w, h, nil, nil, nil, nil)
  if hwnd == nil then
    self:log(("[-] CreateWindowExA failed, GetLastError=%d"):format(tonumber(user32.GetLastError())))
    return nil
  end
  if self.desktop_mode ~= "off" then
    if user32.SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE) == 0 then
      self:log(
        ("[!] SetWindowDisplayAffinity(EXCLUDEFROMCAPTURE) failed, GetLastError=%d"):format(
          tonumber(user32.GetLastError())
        )
      )
    end
  end
  user32.ShowWindow(hwnd, SW_SHOWNOACTIVATE)
  user32.SetWindowPos(hwnd, HWND_TOPMOST, px, py, w, h, _OR(SWP_NOACTIVATE, SWP_SHOWWINDOW))
  self.window_shown = true
  self:log(
    ("[+] hwnd=%s at %d,%d size %dx%d visible=%d exstyle=0x%08X"):format(
      tostring(hwnd),
      px,
      py,
      w,
      h,
      tonumber(user32.IsWindowVisible(hwnd)),
      self:exstyle()
    )
  )
  return hwnd
end

function Overlay:build(w, h)
  self:teardown()

  self.hwnd = self:create_window(w, h)
  if self.hwnd == nil then
    return self:fail("window creation failed")
  end

  local raw_device = obsffi.gs_get_device_obj()
  if raw_device == nil then
    return self:fail("gs_get_device_obj returned nil")
  end
  self.device = raw_device

  local get_ctx = vt(self.device, VT_D3D11DEVICE_GETIMMEDIATECONTEXT, FN.get_ctx)
  out1[0] = nil
  get_ctx(self.device, out1)
  if out1[0] == nil then
    return self:fail("GetImmediateContext returned nil")
  end
  self.context = out1[0]

  local qi = vt(self.device, VT_D3D11DEVICE_QUERYINTERFACE, FN.qi)
  out1[0] = nil
  local hr = qi(self.device, IID_IDXGIDevice, out1)
  if failed(hr) or out1[0] == nil then
    return self:fail("QueryInterface(IDXGIDevice) failed hr=" .. hrstr(hr))
  end
  local dxgi_device = out1[0]

  out1[0] = nil
  local get_adapter = vt(dxgi_device, VT_DXGIDEVICE_GETADAPTER, FN.get_adapter)
  hr = get_adapter(dxgi_device, out1)
  if failed(hr) or out1[0] == nil then
    com_release(dxgi_device)
    return self:fail("IDXGIDevice::GetAdapter failed hr=" .. hrstr(hr))
  end
  local adapter = out1[0]

  if self.desktop_mode ~= "off" then
    local sw = user32.GetSystemMetrics(SM_CXSCREEN)
    local sh = user32.GetSystemMetrics(SM_CYSCREEN)
    if not self:dup_init(adapter, sw, sh) then
      self:log("[!] desktop duplication unavailable: " .. tostring(self.dup_status))
    end
  end

  out1[0] = nil
  local get_parent = vt(adapter, VT_DXGIOBJECT_GETPARENT, FN.get_parent)
  hr = get_parent(adapter, IID_IDXGIFactory2, out1)
  com_release(adapter)
  if failed(hr) or out1[0] == nil then
    com_release(dxgi_device)
    return self:fail("IDXGIAdapter::GetParent(IDXGIFactory2) failed hr=" .. hrstr(hr))
  end
  local factory = out1[0]

  local desc = fnew("DXGI_SWAP_CHAIN_DESC1_T")
  desc.Width = w
  desc.Height = h
  desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM
  desc.Stereo = 0
  desc.SampleDesc.Count = 1
  desc.SampleDesc.Quality = 0
  desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT
  desc.BufferCount = 2
  desc.Scaling = DXGI_SCALING_STRETCH
  desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL
  desc.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED
  desc.Flags = 0

  out1[0] = nil
  local create_sc = vt(factory, VT_DXGIFACTORY2_CREATESWAPCHAINFORCOMPOSITION, FN.create_sc)
  hr = create_sc(factory, self.device, desc, nil, out1)
  com_release(factory)
  if failed(hr) or out1[0] == nil then
    com_release(dxgi_device)
    return self:fail("CreateSwapChainForComposition failed hr=" .. hrstr(hr))
  end
  self.swapchain = out1[0]

  out1[0] = nil
  hr = dcompdll.DCompositionCreateDevice(dxgi_device, IID_IDCompositionDevice, out1)
  com_release(dxgi_device)
  if failed(hr) or out1[0] == nil then
    return self:fail("DCompositionCreateDevice failed hr=" .. hrstr(hr))
  end
  self.dcomp_device = out1[0]

  out1[0] = nil
  local create_target = vt(self.dcomp_device, VT_DCOMPDEVICE_CREATETARGETFORHWND, FN.create_target)
  hr = create_target(self.dcomp_device, self.hwnd, 1, out1)
  if failed(hr) or out1[0] == nil then
    return self:fail("CreateTargetForHwnd failed hr=" .. hrstr(hr))
  end
  self.dcomp_target = out1[0]

  out1[0] = nil
  local create_visual = vt(self.dcomp_device, VT_DCOMPDEVICE_CREATEVISUAL, FN.create_visual)
  hr = create_visual(self.dcomp_device, out1)
  if failed(hr) or out1[0] == nil then
    return self:fail("CreateVisual failed hr=" .. hrstr(hr))
  end
  self.dcomp_visual = out1[0]

  local set_content = vt(self.dcomp_visual, VT_DCOMPVISUAL_SETCONTENT, FN.set_content)
  hr = set_content(self.dcomp_visual, self.swapchain)
  if failed(hr) then
    return self:fail("IDCompositionVisual::SetContent failed hr=" .. hrstr(hr))
  end

  local set_root = vt(self.dcomp_target, VT_DCOMPTARGET_SETROOT, FN.set_root)
  hr = set_root(self.dcomp_target, self.dcomp_visual)
  if failed(hr) then
    return self:fail("IDCompositionTarget::SetRoot failed hr=" .. hrstr(hr))
  end

  local commit = vt(self.dcomp_device, VT_DCOMPDEVICE_COMMIT, FN.commit)
  hr = commit(self.dcomp_device)
  if failed(hr) then
    return self:fail("IDCompositionDevice::Commit failed hr=" .. hrstr(hr))
  end

  self.texrender = obsffi.gs_texrender_create(S.GS_BGRA, S.GS_ZS_NONE)
  if self.texrender == nil then
    return self:fail("gs_texrender_create failed")
  end

  self.blit_effect = obsffi.gs_effect_create(M.PRESENT_EFFECT, "overlay_present", nil)
  if self.blit_effect == nil then
    return self:fail("present effect failed to compile")
  end
  self.blit_params = {
    image = obsffi.gs_effect_get_param_by_name(self.blit_effect, "image"),
    alpha_mode = obsffi.gs_effect_get_param_by_name(self.blit_effect, "alpha_mode"),
    gain = obsffi.gs_effect_get_param_by_name(self.blit_effect, "gain"),
    opacity = obsffi.gs_effect_get_param_by_name(self.blit_effect, "opacity"),
  }

  self.comp_effect = obsffi.gs_effect_create(M.COMPOSITE_EFFECT, "overlay_composite", nil)
  if self.comp_effect == nil then
    return self:fail("desktop composite effect failed to compile")
  end
  self.comp_params = {
    image = obsffi.gs_effect_get_param_by_name(self.comp_effect, "image"),
    image2 = obsffi.gs_effect_get_param_by_name(self.comp_effect, "image2"),
    mode = obsffi.gs_effect_get_param_by_name(self.comp_effect, "mode"),
    opacity = obsffi.gs_effect_get_param_by_name(self.comp_effect, "opacity"),
    gain = obsffi.gs_effect_get_param_by_name(self.comp_effect, "gain"),
    dim = obsffi.gs_effect_get_param_by_name(self.comp_effect, "dim"),
  }

  self.fn_get_buffer = vt(self.swapchain, VT_DXGISWAPCHAIN_GETBUFFER, FN.get_buffer)
  self.fn_present = vt(self.swapchain, VT_DXGISWAPCHAIN_PRESENT, FN.present)
  self.fn_copy = vt(self.context, VT_D3D11CONTEXT_COPYRESOURCE, FN.copy_resource)

  self.width, self.height = w, h
  self.ready = true
  self.last_error = "none"
  self:log(("[+] ready %dx%d"):format(w, h))
  return true
end

function Overlay:set_click_through(v)
  self.click_through = v and true or false
  if self.hwnd == nil then
    return
  end
  local ex = bit.band(
    tonumber(user32.GetWindowLongPtrA(self.hwnd, GWL_EXSTYLE)),
    bit.bnot(_OR(WS_EX_TRANSPARENT, WS_EX_LAYERED))
  )
  if self.click_through then
    ex = _OR(ex, WS_EX_TRANSPARENT, WS_EX_LAYERED)
  end
  user32.SetWindowLongPtrA(self.hwnd, GWL_EXSTYLE, ex)
  user32.SetWindowPos(
    self.hwnd,
    nil,
    0,
    0,
    0,
    0,
    _OR(SWP_NOMOVE, SWP_NOSIZE, SWP_NOZORDER, SWP_NOACTIVATE, SWP_FRAMECHANGED)
  )
end

function Overlay:enable(v)
  v = v and true or false
  if v and self.disabled_by_error then
    self.disabled_by_error = false
    self.last_error = "none"
  end
  self.enabled = v
end

function Overlay:active()
  return self.enabled and not self.disabled_by_error
end

function Overlay:pump()
  if self.hwnd == nil then
    return
  end
  while user32.PeekMessageA(msg_buf, nil, 0, 0, PM_REMOVE) ~= 0 do
    user32.TranslateMessage(msg_buf)
    user32.DispatchMessageA(msg_buf)
  end
end

function Overlay:present(src_tex)
  if not self.ready or src_tex == nil then
    return
  end
  local src_obj = obsffi.gs_texture_get_obj(src_tex)
  if src_obj == nil then
    return
  end

  out1[0] = nil
  local hr = self.fn_get_buffer(self.swapchain, 0, IID_ID3D11Texture2D, out1)
  if failed(hr) or out1[0] == nil then
    if self.last_present_hr ~= hr then
      self.last_present_hr = hr
      self:log("[-] GetBuffer failed hr=" .. hrstr(hr))
    end
    return
  end
  local backbuffer = out1[0]

  self.fn_copy(self.context, backbuffer, src_obj)
  com_release(backbuffer)

  hr = self.fn_present(self.swapchain, 0, 0)
  if self.last_present_hr ~= hr then
    self.last_present_hr = hr
    if failed(hr) then
      self:log("[-] Present failed hr=" .. hrstr(hr))
    else
      self:log("[+] Present ok hr=" .. hrstr(hr))
    end
  end
  self.presented = self.presented + 1
end

function Overlay:draw_composite(w, h, tex)
  local p = self.comp_params
  if self.comp_effect == nil or p == nil or self.desk_tex == nil then
    return false
  end
  obsffi.gs_effect_set_texture(p.image, self.desk_tex)
  obsffi.gs_effect_set_texture(p.image2, tex)
  obsffi.gs_effect_set_float(p.mode, DESKTOP_MODE_INDEX[self.desktop_mode] or 0)
  obsffi.gs_effect_set_float(p.opacity, self.desk_opacity or M.DEFAULT_DESKTOP_OPACITY)
  obsffi.gs_effect_set_float(p.gain, self.desk_gain or M.DEFAULT_DESKTOP_GAIN)
  obsffi.gs_effect_set_float(p.dim, self.desk_dim or M.DEFAULT_DESKTOP_DIM)
  while obsffi.gs_effect_loop(self.comp_effect, "Draw") do
    obsffi.gs_draw_sprite(tex, 0, w, h)
  end
  return true
end

function Overlay:_render_inner(w, h, draw_fn, clear_col)
  if not self.ready or self.width ~= w or self.height ~= h or self.rebuild_wanted then
    self.rebuild_wanted = false
    if not self:build(w, h) then
      return false
    end
  end

  if self.desktop_mode ~= "off" and self.dup ~= nil then
    self:dup_capture()
  end

  obsffi.gs_texrender_reset(self.texrender)
  if not obsffi.gs_texrender_begin(self.texrender, w, h) then
    return true
  end

  local ok, err = pcall(function()
    S.gs_clear(S.GS_CLEAR_COLOR, clear_col, 0, 0)
    S.gs_blend_state_push()
    S.gs_enable_blending(false)
    S.gs_ortho(0, w, 0, h, -100.0, 100.0)
    draw_fn(w, h)
    S.gs_blend_state_pop()
  end)

  obsffi.gs_texrender_end(self.texrender)

  if not ok then
    error(err, 0)
  end

  self:present(obsffi.gs_texrender_get_texture(self.texrender))
  return true
end

function Overlay:render(w, h, draw_fn, clear_col)
  if not self.enabled or self.disabled_by_error then
    if self.ready or self.hwnd ~= nil then
      self:teardown()
    end
    return
  end
  if w < 1 or h < 1 then
    return
  end

  self:update_suspend()
  if self.suspended then
    self:set_window_shown(false)
    return
  end
  self:set_window_shown(true)

  local ok, err = xpcall(function()
    return self:_render_inner(w, h, draw_fn, clear_col)
  end, debug.traceback)

  if not ok then
    self.last_error = tostring(err)
    self:log("[-] render error, overlay disabled:\n" .. tostring(err))
    self:teardown()
    self.enabled = false
    self.disabled_by_error = true
  elseif err == false then
    self.enabled = false
    self.disabled_by_error = true
    self:log("[-] build failed, overlay disabled until re-enabled")
  end
end

function Overlay:diagnostics()
  print(("-- overlay %s  %dx%d"):format(self.name, self.width, self.height))
  print("   enabled          : " .. tostring(self.enabled))
  print("   disabled_by_error: " .. tostring(self.disabled_by_error))
  print("   click_through    : " .. tostring(self.click_through))
  print("   ready            : " .. tostring(self.ready))
  print("   hwnd             : " .. tostring(self.hwnd))
  if self.hwnd ~= nil then
    print("   hwnd visible     : " .. tonumber(user32.IsWindowVisible(self.hwnd)))
    print(
      "   hwnd exstyle     : " .. string.format("0x%08X", tonumber(user32.GetWindowLongPtrA(self.hwnd, GWL_EXSTYLE)))
    )
  end
  print("   swapchain        : " .. tostring(self.swapchain))
  print("   dcomp_device     : " .. tostring(self.dcomp_device))
  print("   dcomp_visual     : " .. tostring(self.dcomp_visual))
  print("   desktop dup      : " .. tostring(self.dup))
  print("   dup status       : " .. tostring(self.dup_status))
  print("   desktop mode     : " .. tostring(self.desktop_mode))
  print("   frames captured  : " .. tostring(self.captured))
  print("   pointer-only     : " .. tostring(self.pointer_only))
  print("   focus hide       : " .. tostring(self.focus_hide) .. " / " .. tostring(self.focus_delay) .. "s")
  print("   suspended        : " .. tostring(self.suspended))
  print("   host focused     : " .. tostring(self:host_focused()))
  print("   texrender        : " .. tostring(self.texrender))
  print("   frames presented : " .. self.presented)
  print("   last_present     : " .. hrstr(self.last_present_hr))
  print("   last_error       : " .. tostring(self.last_error))
end

function M.libs_ok()
  return obsffi ~= nil and user32 ~= nil and dcompdll ~= nil
end

M.PRESENT_EFFECT = [[
#define SamplerState sampler_state
#define Texture2D texture2d
uniform float4x4 ViewProj;
uniform Texture2D image;
uniform float alpha_mode;
uniform float gain;
uniform float opacity;

SamplerState blitSampler {
    Filter   = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};
struct VertDataIn {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};
struct VertDataOut {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};
VertDataOut VSBlit(VertDataIn v_in)
{
    VertDataOut vert_out;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    vert_out.uv  = v_in.uv;
    return vert_out;
}

float4 PSPresent(VertDataOut v_in) : TARGET
{
    float4 c = image.Sample(blitSampler, v_in.uv);
    int m = int(alpha_mode + 0.5);

    // the same four conversions the base effects used to do, unchanged
    float4 p = c;                                            // 0: straight, as-is
    if (m == 1) { p = float4(c.rgb / max(c.a, 1e-4), c.a); }  // un-premultiply
    if (m == 2) { p = float4(c.rgb * c.a, c.a); }             // premultiply
    if (m == 3) { p = float4(c.rgb, 1.0); }                   // opaque

    p.rgb *= gain;
    return p * opacity;
}

technique Draw
{
    pass { vertex_shader = VSBlit(v_in); pixel_shader = PSPresent(v_in); }
}
]]

M.COMPOSITE_EFFECT = [[
#define SamplerState sampler_state
#define Texture2D texture2d
uniform float4x4 ViewProj;
uniform Texture2D image;    // the captured desktop
uniform Texture2D image2;   // the effect, premultiplied
uniform float mode;
uniform float opacity;
uniform float gain;
uniform float dim;

SamplerState compSampler {
    Filter   = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};
struct VertDataIn {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};
struct VertDataOut {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};
VertDataOut VSComposite(VertDataIn v_in)
{
    VertDataOut vert_out;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    vert_out.uv  = v_in.uv;
    return vert_out;
}

float3 blend_surface(int m, float3 d, float3 s)
{
    if (m == 3) return max(d, s);
    if (m == 4) return min(d, s);
    if (m == 5) return d * s;
    if (m == 6) return lerp(2.0 * d * s, 1.0 - 2.0 * (1.0 - d) * (1.0 - s), step(0.5, d));
    if (m == 7) return (1.0 - 2.0 * s) * d * d + 2.0 * s * d;   // Pegtop soft light
    if (m == 8) return saturate(d / max(1.0 - s, 0.004));
    if (m == 9) return abs(d - s);
    return s;                                                    // 0: normal
}

float4 PSComposite(VertDataOut v_in) : TARGET
{
    float3 d = image.Sample(compSampler, v_in.uv).rgb;
    float4 s = image2.Sample(compSampler, v_in.uv);
    int m = int(mode + 0.5);

    float a = saturate(s.a * opacity);
    d *= 1.0 - saturate(dim) * a;

    float3 sp = s.rgb * gain * opacity;
    if (m == 1) return float4(d + sp, 1.0);
    if (m == 2) return float4(d + sp - d * sp, 1.0);

    float3 sc = saturate(s.rgb / max(s.a, 1e-4) * gain);
    return float4(lerp(d, blend_surface(m, d, sc), a), 1.0);
}

technique Draw
{
    pass { vertex_shader = VSComposite(v_in); pixel_shader = PSComposite(v_in); }
}
]]

M.ALPHA_MODES = {
  { "straight alpha (as-is)", "straight" },
  { "un-premultiply (rgb / a)", "unpremul" },
  { "premultiply (rgb * a)", "premul" },
  { "opaque (a = 1)", "opaque" },
}

M.DEFAULT_ALPHA_MODE = "straight"

function M.draw_texture(tex, w, h, content)
  if tex == nil then
    return
  end
  local effect
  if content == "premul" then
    effect = obsffi.obs_get_base_effect(S.OBS_EFFECT_PREMULTIPLIED_ALPHA)
  else
    effect = obsffi.obs_get_base_effect(S.OBS_EFFECT_DEFAULT)
  end
  if effect == nil then
    return
  end
  obsffi.gs_effect_set_texture(obsffi.gs_effect_get_param_by_name(effect, "image"), tex)
  while obsffi.gs_effect_loop(effect, "Draw") do
    obsffi.gs_draw_sprite(tex, 0, w, h)
  end
end

function M.add_detach_property(props, id, label)
  return S.obs_properties_add_bool(props, id or "_detach", label or "detached overlay window")
end

function M.add_alpha_mode_list(props, id, label)
  local list = S.obs_properties_add_list(
    props,
    id or "_alpha_mode",
    label or "overlay alpha mode",
    S.OBS_COMBO_TYPE_LIST,
    S.OBS_COMBO_FORMAT_STRING
  )
  for _, entry in ipairs(M.ALPHA_MODES) do
    S.obs_property_list_add_string(list, entry[1], entry[2])
  end
  return list
end

function M.read_alpha_mode(settings, id)
  local mode = S.obs_data_get_string(settings, id or "_alpha_mode")
  if mode == nil or mode == "" then
    return M.DEFAULT_ALPHA_MODE
  end
  return mode
end

-- must match the branch order in PSPresent
local ALPHA_MODE_INDEX = { straight = 0, unpremul = 1, premul = 2, opaque = 3 }

function Overlay:render_texture(w, h, tex, mode)
  mode = mode or M.DEFAULT_ALPHA_MODE
  if self.desktop_mode ~= "off" then
    mode = "premul"
  end
  local this = self
  self.zero_col = self.zero_col or S.vec4()
  self.zero_col.x, self.zero_col.y, self.zero_col.z, self.zero_col.w = 0, 0, 0, 0
  self:render(w, h, function(ow, oh)
    if tex == nil then
      return
    end
    if this.desktop_mode ~= "off" and this.have_desk and this:draw_composite(ow, oh, tex) then
      return
    end
    local p = this.blit_params
    if this.blit_effect == nil or p == nil then
      return
    end
    obsffi.gs_effect_set_texture(p.image, tex)
    obsffi.gs_effect_set_float(p.alpha_mode, ALPHA_MODE_INDEX[mode] or 0)
    obsffi.gs_effect_set_float(p.gain, this.desk_gain or M.DEFAULT_DESKTOP_GAIN)
    obsffi.gs_effect_set_float(p.opacity, this.desk_opacity or M.DEFAULT_DESKTOP_OPACITY)
    while obsffi.gs_effect_loop(this.blit_effect, "Draw") do
      obsffi.gs_draw_sprite(tex, 0, ow, oh)
    end
  end, self.zero_col)
end

local FilterDef = {}
local INSTANCES = {}

function FilterDef:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function FilterDef:create(source)
  local instance = {}
  instance.source = source
  instance.ov = M.new("desktop overlay")
  instance.alpha_mode = M.DEFAULT_ALPHA_MODE
  instance.last_w, instance.last_h = 0, 0
  instance.load_and_toggle = false

  S.obs_enter_graphics()
  instance.tr = obsffi.gs_texrender_create(S.GS_RGBA, S.GS_ZS_NONE)
  instance.clear_col = S.vec4()
  instance.clear_col.x, instance.clear_col.y, instance.clear_col.z, instance.clear_col.w = 0, 0, 0, 0
  S.obs_leave_graphics()

  FilterDef.update(instance, self)
  -- instance.ov:enable(false)
  table.insert(INSTANCES, instance)
  return instance
end

function FilterDef:destroy()
  S.obs_enter_graphics()
  if self.ov then
    self.ov:teardown()
  end
  if self.tr ~= nil then
    obsffi.gs_texrender_destroy(self.tr)
    self.tr = nil
  end
  S.obs_leave_graphics()
  for i, inst in ipairs(INSTANCES) do
    if inst == self then
      table.remove(INSTANCES, i)
      break
    end
  end
end

function FilterDef:get_name()
  return "[🪟] Desktop overlay by upgradeQ"
end

function FilterDef:get_properties()
  local props = S.obs_properties_create()
  M.add_detach_property(props, "_detach", "detached overlay window")
  M.add_alpha_mode_list(props, "_alpha_mode", "overlay alpha mode")
  M.add_desktop_mode_list(props, "_desktop", "blend with desktop (costly)")
  M.add_desktop_opacity_slider(props, "_ovopacity", "overlay opacity")
  M.add_desktop_gain_slider(props, "_ovgain", "overlay brightness")
  M.add_desktop_dim_slider(props, "_ovdim", "dim desktop under effect")
  M.add_position_sliders(props, "_ovx", "_ovy")
  M.add_focus_hide_toggle(props, "_ovfocus", "hide overlay while OBS is focused")
  M.add_focus_delay_slider(props, "_ovdelay", "seconds before overlay returns")

  S.obs_properties_add_button(props, "_diag", "Print diagnostics to script log", function()
    for _, inst in ipairs(INSTANCES) do
      FilterDef.diagnostics(inst)
      inst.ov:diagnostics()
    end
    return false
  end)
  return props
end

function FilterDef:diagnostics()
  print("-- desktop overlay filter")
  print(("   captured               : %dx%d"):format(self.last_w or 0, self.last_h or 0))
  print(("   captures / passthrough : %d / %d"):format(self.n_capture or 0, self.n_skip or 0))
  print(("   alpha mode             : %s"):format(tostring(self.alpha_mode)))
end

function FilterDef:update(settings)
  if not self.load_and_toggle then
    local source = self.source
    S.timer_add(function()
      S.obs_source_set_enabled(source, false)
      S.timer_add(function()
        S.obs_source_set_enabled(source, true)
        S.remove_current_callback()
      end, 1000)
      S.remove_current_callback()
    end, 500)

    self.load_and_toggle = true
  end
  self.alpha_mode = M.read_alpha_mode(settings, "_alpha_mode")
  self.ov:set_desktop_mode(M.read_desktop_mode(settings, "_desktop"))
  self.ov:set_desktop_levels(
    M.read_desktop_opacity(settings, "_ovopacity"),
    M.read_desktop_gain(settings, "_ovgain"),
    M.read_desktop_dim(settings, "_ovdim")
  )
  self.ov:set_position(M.read_position(settings, "_ovx", "_ovy"))
  self.ov:set_focus_hide(M.read_focus_hide(settings, "_ovfocus"), M.read_focus_delay(settings, "_ovdelay"))
  self.ov:enable(S.obs_data_get_bool(settings, "_detach"))
  self.ov:set_click_through(true)
end

function FilterDef:get_defaults()
  S.obs_data_set_default_bool(self, "_detach", false)
  S.obs_data_set_default_string(self, "_alpha_mode", M.DEFAULT_ALPHA_MODE)
  S.obs_data_set_default_string(self, "_desktop", M.DEFAULT_DESKTOP_MODE)
  S.obs_data_set_default_double(self, "_ovopacity", M.DEFAULT_DESKTOP_OPACITY)
  S.obs_data_set_default_double(self, "_ovgain", M.DEFAULT_DESKTOP_GAIN)
  S.obs_data_set_default_double(self, "_ovdim", M.DEFAULT_DESKTOP_DIM)
  S.obs_data_set_default_int(self, "_ovx", 0)
  S.obs_data_set_default_int(self, "_ovy", 0)
  S.obs_data_set_default_bool(self, "_ovfocus", M.DEFAULT_FOCUS_HIDE)
  S.obs_data_set_default_int(self, "_ovdelay", 2)
end

function FilterDef:video_tick(seconds)
  self.ov:pump()
end

local function capture(self, src, w, h)
  obsffi.gs_texrender_reset(self.tr)
  if not obsffi.gs_texrender_begin(self.tr, w, h) then
    return nil
  end
  S.gs_blend_state_push()
  S.gs_blend_function(S.GS_BLEND_ONE, S.GS_BLEND_ZERO)
  S.gs_clear(S.GS_CLEAR_COLOR, self.clear_col, 0, 0)
  S.gs_ortho(0, w, 0, h, -100.0, 100.0)
  S.obs_source_video_render(src)
  S.gs_blend_state_pop()
  obsffi.gs_texrender_end(self.tr)
  return obsffi.gs_texrender_get_texture(self.tr)
end

function FilterDef:video_render(effect)
  if not self.ov:active() then
    self.ov:render_texture(1, 1, nil, self.alpha_mode)
    self.n_skip = (self.n_skip or 0) + 1
    S.obs_source_skip_video_filter(self.source)
    return
  end

  local target = S.obs_filter_get_target(self.source)
  local w = target ~= nil and S.obs_source_get_base_width(target) or 0
  local h = target ~= nil and S.obs_source_get_base_height(target) or 0
  if target == nil or w == 0 or h == 0 then
    self.n_skip = (self.n_skip or 0) + 1
    S.obs_source_skip_video_filter(self.source)
    return
  end

  local tex = capture(self, target, w, h)
  self.last_w, self.last_h = w, h
  self.n_capture = (self.n_capture or 0) + 1
  self.ov:render_texture(w, h, tex, self.alpha_mode)

  if tex == nil then
    S.obs_source_skip_video_filter(self.source)
    return
  end
  M.draw_texture(tex, w, h, "straight")
end

function script_load(settings)
  if not M.libs_ok() then
    print("[desktop overlay] obs / user32 / dcomp did not all load - the overlay will not work")
  end
  S.obs_register_source(FilterDef:new({
    id = "cursor_skin_overlay_filter",
    type = S.OBS_SOURCE_TYPE_FILTER,
    output_flags = S.OBS_SOURCE_VIDEO,
  }))
end

function script_description()
  return [[
<h2> obs-desktop-hud </h2>
Puts any source in a click-through window over your desktop.<br/>
<a style="color: #0000ff; text-decoration: none; font-size:26px;"
Copyright &copy; 2026 upgradeQ<br/>
Distributed under <a style="color: #ffffff; text-decoration: none;"> MIT license</a>
]]
end