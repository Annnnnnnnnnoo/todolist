Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WT2 {
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr a, int x, int y, int w, int h, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT2 rect);
}
public struct RECT2 { public int Left, Top, Right, Bottom; }
"@
$p=Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if(-not $p){Write-Output "NO_PROCESS";exit 1}
$h=$p.MainWindowHandle
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=[System.Drawing.Bitmap]::new($sw.Width,$sw.Height)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$pos=@(@(60,60),@(1000,150),@(500,200))
foreach($pt in $pos){
  [WT2]::SetWindowPos($h,[IntPtr]::Zero,$pt[0],$pt[1],340,520,0x0044)|Out-Null
  Start-Sleep -Milliseconds 2000
  $r=New-Object RECT2; [WT2]::GetWindowRect($h,[ref]$r)|Out-Null
  $g.CopyFromScreen(0,0,0,0,$bmp.Size)
  $xl=$r.Left;$yt=$r.Top
  $pts=@(@("padL",$xl+6,$yt+260),@("cardL",$xl+20,$yt+260),@("cardC",$xl+170,$yt+260),@("cardR",$xl+320,$yt+260),@("padR",$xl+334,$yt+260))
  $row="actualWin=($xl,$yt) "
  foreach($pp in $pts){
    $c=$bmp.GetPixel($pp[1],$pp[2])
    $row+=("{0}={1},{2},{3} " -f $pp[0],$c.R,$c.G,$c.B)
  }
  Write-Output $row
}
[WT2]::SetWindowPos($h,[IntPtr]::Zero,60,60,340,520,0x0044)|Out-Null
$g.Dispose();$bmp.Dispose()
Write-Output "DONE"
