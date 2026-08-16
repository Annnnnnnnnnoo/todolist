Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECTM { public int Left, Top, Right, Bottom; }
public class WM {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECTM rect);
}
"@
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=[System.Drawing.Bitmap]::new($sw.Width,$sw.Height)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0,0,0,0,$bmp.Size)

function C($name,$c){ Write-Output ("{0}: rgb({1},{2},{3}) lum={4}" -f $name,$c[0],$c[1],$c[2],[int](($c[0]*0.299)+($c[1]*0.587)+($c[2]*0.114))) }
$L=177;$T=177
Write-Output "=== 窗口内像素（相对坐标）==="
foreach($y in @(6,150,260,400,510)){
  $a=$bmp.GetPixel($L+6,$T+$y);   C "x6  y$y" @($a.R,$a.G,$a.B)
  $b=$bmp.GetPixel($L+170,$T+$y); C "x170 y$y" @($b.R,$b.G,$b.B)
  $c=$bmp.GetPixel($L+333,$T+$y); C "x333 y$y" @($c.R,$c.G,$c.B)
}
Write-Output "=== ASCII 亮度图 (15px/格; [=窗口内, .=浅色 +=中 #=深色) ==="
$step=15
for($gy=0;$gy -lt 48;$gy++){
  $line=""
  for($gx=0;$gx -lt 34;$gx++){
    $sx=$L-60+$gx*$step; $sy=$T-60+$gy*$step
    if($sx -lt 0 -or $sy -lt 0 -or $sx -ge $sw.Width -or $sy -ge $sw.Height){ $line+="?"; continue }
    $px=$bmp.GetPixel($sx,$sy)
    $lum=[int](($px.R*0.299)+($px.G*0.587)+($px.B*0.114))
    $inside=($sx -ge $L -and $sx -lt ($L+340) -and $sy -ge $T -and $sy -lt ($T+520))
    $ch=if($lum -gt 200){"."}elseif($lum -gt 140){"+"}elseif($lum -gt 70){"o"}elseif($lum -gt 30){"*"}else{"#"}
    if($inside){ $ch="["+$ch+"]" }
    $line+=$ch
  }
  Write-Output $line
}
$g.Dispose();$bmp.Dispose()
Write-Output "DONE"
