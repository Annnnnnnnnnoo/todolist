Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# 找到 todolist 主窗口
$proc = Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Write-Output "no-process"; exit }
$rect = $proc.MainWindowHandle
if ($rect -eq 0) { Write-Output "no-window-handle"; exit }

# 获取窗口矩形
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public class W {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
"@
$r = New-Object RECT
[W]::GetWindowRect($proc.MainWindowHandle, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$h = $r.Bottom - $r.Top
Write-Output "window rect: ($($r.Left),$($r.Top)) size ${w}x${h}"

# 截屏
$b = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $b.Size)

function Sample($name, $x, $y) {
  $c = $b.GetPixel($x, $y)
  Write-Output ("{0} ({1},{2}): R={3} G={4} B={5} A={6}" -f $name, $x, $y, $c.R, $c.G, $c.B, $c.A)
}

Sample "左上padding(6,6)" 6 6
Sample "卡内标题区(170,30)" 170 30
Sample "中心(170,260)" 170 260
Sample "输入框区(170,80)" 170 80
Sample "卡内左下(170,500)" 170 500
Sample "卡边缘(10,260)" 10 260

$b.Save("D:\todolist\.debug\win.png")
$g.Dispose(); $b.Dispose()
