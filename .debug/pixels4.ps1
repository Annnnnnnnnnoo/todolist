Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT4 { public int Left, Top, Right, Bottom; }
public class W4 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT4 rect);
}
"@
$p = Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output "NO_PROCESS"; exit 1 }
$r = New-Object RECT4
[W4]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$L=$r.Left; $T=$r.Top; $W=$r.Right-$r.Left; $H=$r.Bottom-$r.Top
Write-Output "WINDOW L=$L T=$T W=$W H=$H"
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
Write-Output "SCREEN W=$($sw.Width) H=$($sw.Height)"
$bmp = [System.Drawing.Bitmap]::new($sw.Width, $sw.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0,0,0,0,$bmp.Size)
function S($name,$sx,$sy){
  $c=$bmp.GetPixel($sx,$sy)
  Write-Output ("{0}: RGB({1},{2},{3})" -f $name,$c.R,$c.G,$c.B)
}
# 窗口内部 padding（应透明→看到桌面）
S "pad(6,6)    @" ($L+6)   ($T+6)
S "pad(6,150)  @" ($L+6)   ($T+150)
S "pad(6,260)  @" ($L+6)   ($T+260)
S "pad(6,400)  @" ($L+6)   ($T+400)
S "pad(6,510)  @" ($L+6)   ($T+510)
S "pad(333,260)@" ($L+333) ($T+260)
# 卡片中心
S "card_center @" ($L+170) ($T+260)
# 桌面——窗口外同高度，各方向
S "desktop_L_y437@" ($L-60) ($T+260)
S "desktop_L_y577@" ($L-60) ($T+400)
S "desktop_A_y183 @" ($L+170) ($T-40)
S "desktop_R_y437@" ($L+$W+40) ($T+260)
S "desktop_B_y697@" ($L+170) ($T+$H+40)
$g.Dispose(); $bmp.Dispose()
Write-Output "DONE"
