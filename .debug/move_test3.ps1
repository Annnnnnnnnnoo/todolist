Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WT3 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT3 rect);
}
public struct RECT3 { public int Left, Top, Right, Bottom; }
"@
$p=Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if(-not $p){Write-Output "NO_PROCESS";exit 1}
$r=New-Object RECT3; [WT3]::GetWindowRect($p.MainWindowHandle,[ref]$r)|Out-Null
$xl=$r.Left;$yt=$r.Top;$w=$r.Right-$r.Left;$h=$r.Bottom-$r.Top
Write-Output "CURRENT_WIN ($xl,$yt) ${w}x${h}"
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=[System.Drawing.Bitmap]::new($sw.Width,$sw.Height)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0,0,0,0,$bmp.Size)
foreach($y in @(60,150,260,400)){
  $out="y$y : "
  foreach($x in @(6,60,170,300,334)){
    $c=$bmp.GetPixel($xl+$x,$yt+$y)
    $out += "x${x}=$($c.R),$($c.G),$($c.B) "
  }
  Write-Output $out
}
$g.Dispose();$bmp.Dispose()
Write-Output "DONE"
