Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public class W {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
}
"@

$p = Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output "NO_PROCESS"; exit 1 }
$h = $p.MainWindowHandle
if ($h -eq 0) { Write-Output "NO_HANDLE"; exit 1 }

$r = New-Object RECT
[W]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$ht = $r.Bottom - $r.Top
Write-Output "RECT L=$($r.Left) T=$($r.Top) W=$w H=$ht"

$b = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $b.Size)

$pts = @(
  @("pad_topleft", 6, 6),
  @("pad_left_mid", 6, 260),
  @("card_center", 170, 260),
  @("card_title", 170, 30),
  @("card_input", 170, 80),
  @("card_bottom", 170, 500)
)
foreach ($pt in $pts) {
  $c = $b.GetPixel($pt[1], $pt[2])
  Write-Output ("{0}: RGB({1},{2},{3})" -f $pt[0], $c.R, $c.G, $c.B)
}
$b.Save("D:\todolist\.debug\win2.png")
$g.Dispose(); $b.Dispose()
Write-Output "DONE"
