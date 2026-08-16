Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT3 { public int Left, Top, Right, Bottom; }
public class W3 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT3 rect);
}
"@
$p = Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output "NO_PROCESS"; exit 1 }
$h = $p.MainWindowHandle
$r = New-Object RECT3
[W3]::GetWindowRect($h, [ref]$r) | Out-Null
$L=$r.Left; $T=$r.Top; $W=$r.Right-$r.Left; $H=$r.Bottom-$r.Top
Write-Output "WINDOW L=$L T=$T W=$W H=$H"

$b = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen($L, $T, 0, 0, $b.Size)

function S($name,$sx,$sy){
  $c=$b.GetPixel($sx,$sy)
  Write-Output ("{0}: RGB({1},{2},{3})" -f $name,$c.R,$c.G,$c.B)
}
# 窗口内 padding 区（应透明→显示桌面/亚克力）
S "win_pad_top6" 6 6
S "win_pad_top150" 6 150
S "win_pad_top260" 6 260
S "win_pad_top400" 6 400
S "win_pad_top510" 6 510
S "win_pad_right" 333 260
# 卡片内部
S "win_card_center" 170 260
# 桌面（窗口外，同高度）
$b2 = New-Object System.Drawing.Bitmap(400, 700)
$g2 = [System.Drawing.Graphics]::FromImage($b2)
$g2.CopyFromScreen($L-200, $T-50, 0, 0, $b2.Size)
S "desktop_left_above" 100 150
S "desktop_left_sameY" 100 310
S "desktop_above_win" 200 30
$b2.Dispose(); $g2.Dispose()
$b.Dispose(); $g.Dispose()
Write-Output "DONE"
