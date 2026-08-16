Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECTS { public int Left, Top, Right, Bottom; }
public class WS {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECTS rect);
}
"@
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=[System.Drawing.Bitmap]::new($sw.Width,$sw.Height)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0,0,0,0,$bmp.Size)
$bmp.Save("D:\todolist\.debug\fullscreen.png",[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bmp.Dispose()
Write-Output "FULLSCREEN SAVED"

$p=Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if($p){
  $r=New-Object RECTS
  [WS]::GetWindowRect($p.MainWindowHandle,[ref]$r)|Out-Null
  $L=$r.Left;$T=$r.Top;$W=$r.Right-$r.Left;$H=$r.Bottom-$r.Top
  $bmp2=[System.Drawing.Bitmap]::new($W,$H)
  $g2=[System.Drawing.Graphics]::FromImage($bmp2)
  $g2.CopyFromScreen($L,$T,0,0,$bmp2.Size)
  $bmp2.Save("D:\todolist\.debug\window.png",[System.Drawing.Imaging.ImageFormat]::Png)
  $g2.Dispose();$bmp2.Dispose()
  Write-Output "WINDOW SAVED L=$L T=$T W=$W H=$H"
}else{Write-Output "NO_PROCESS"}
