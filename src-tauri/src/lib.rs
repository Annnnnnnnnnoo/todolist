use tauri::window::Color;
use tauri::Manager;

/// 关闭按钮触发：直接退出整个应用
#[tauri::command]
fn quit(app: tauri::AppHandle) {
    app.exit(0);
}

// ===== SWCA 亚克力（SetWindowCompositionAttribute, ACCENT_ENABLE_ACRYLICBLURBEHIND）=====
// 分层窗口(transparent:true)下 DWM 系统 backdrop(DWMSBT) 不生效，必须走 SWCA。
// window-vibrancy 的 apply_acrylic 在 Win11 build>=22523 会走 DWMSBT 分支且忽略返回值，
// 所以这里自己实现 SWCA 亚克力模糊。
#[cfg(target_os = "windows")]
mod acrylic {
    use windows_sys::Win32::Foundation::HWND;
    use windows_sys::Win32::System::LibraryLoader::{GetProcAddress, LoadLibraryA};

    const ACCENT_ENABLE_ACRYLICBLURBEHIND: u32 = 4;
    const WCA_ACCENT_POLICY: u32 = 19;

    #[repr(C)]
    struct ACCENT_POLICY {
        accent_state: u32,
        accent_flags: u32,
        gradient_color: u32,
        animation_id: u32,
    }

    #[repr(C)]
    struct WINDOWCOMPOSITIONATTRIBDATA {
        attrib: u32,
        pv_data: *mut core::ffi::c_void,
        cb_data: usize,
    }

    type SetWindowCompositionAttributeFn =
        unsafe extern "system" fn(HWND, *mut WINDOWCOMPOSITIONATTRIBDATA) -> i32;

    fn rgba_to_abgr(r: u8, g: u8, b: u8, a: u8) -> u32 {
        (r as u32) | ((g as u32) << 8) | ((b as u32) << 16) | ((a as u32) << 24)
    }

    pub fn apply(hwnd: isize) -> Result<(), String> {
        unsafe {
            let module = LoadLibraryA("user32.dll\0".as_ptr());
            if module.is_null() {
                return Err("无法加载 user32.dll".into());
            }
            let proc = GetProcAddress(module, "SetWindowCompositionAttribute\0".as_ptr());
            let Some(func) = proc else {
                return Err("找不到 SetWindowCompositionAttribute".into());
            };
            let set_wca: SetWindowCompositionAttributeFn =
                std::mem::transmute::<_, SetWindowCompositionAttributeFn>(func);

            // alpha=0 会让亚克力失效，这里给个几乎透明的黑(视觉由前端卡片决定)
            let mut policy = ACCENT_POLICY {
                accent_state: ACCENT_ENABLE_ACRYLICBLURBEHIND,
                accent_flags: 0,
                gradient_color: rgba_to_abgr(0, 0, 0, 1),
                animation_id: 0,
            };
            let mut data = WINDOWCOMPOSITIONATTRIBDATA {
                attrib: WCA_ACCENT_POLICY,
                pv_data: (&mut policy as *mut ACCENT_POLICY) as *mut core::ffi::c_void,
                cb_data: std::mem::size_of::<ACCENT_POLICY>(),
            };
            let ok = set_wca(hwnd as HWND, &mut data);
            if ok != 0 {
                Ok(())
            } else {
                Err(format!("SetWindowCompositionAttribute 返回 {ok}"))
            }
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            // Windows 下应用亚克力毛玻璃效果。
            // 分层窗口(transparent:true) -> WebView2 完整 alpha 合成 -> rgba 卡片能叠在模糊上。
            #[cfg(target_os = "windows")]
            {
                if let Some(window) = app.get_webview_window("main") {
                    use raw_window_handle::HasWindowHandle;

                    // 1. 设置 WebView 背景全透明
                    if let Err(e) = window.set_background_color(Some(Color(0, 0, 0, 0))) {
                        eprintln!("[todolist] 设置透明 WebView 背景失败: {e}");
                    }
                    // 2. SWCA 亚克力模糊（在分层窗口上生效）
                    if let Ok(handle) = window.window_handle() {
                        if let raw_window_handle::RawWindowHandle::Win32(win) = handle.as_raw() {
                            if let Err(e) = acrylic::apply(win.hwnd.get() as isize) {
                                eprintln!("[todolist] SWCA 亚克力失败: {e}");
                            }
                        }
                    }
                } else {
                    eprintln!("[todolist] 未找到主窗口 main");
                }
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![quit])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
