Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public struct RECTT { public int Left, Top, Right, Bottom; }
public class WT {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECTT rect);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr a, int x, int y, int w, int h, uint f);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
$p=Get-Process -Name "todolist" -ErrorAction SilentlyContinue | Select-Object -First 1
if(-not $p){Write-Output "NO_PROCESS";exit 1}
$h=$p.MainWindowHandle
$sw=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=[System.Drawing.Bitmap]::new($sw.Width,$sw.Height)
$g=[System.Drawing.Graphics]::FromImage($bmp)

function SampleAt($x,$y){
  [WT]::SetWindowPos($h,[IntPtr]::Zero,$x,$y,340,520,0x0044) | Out-Null
  Start-Sleep -Milliseconds 900
  $g.CopyFromScreen(0,0,0,0,$bmp.Size)
  $pad=$bmp.GetPixel($x+6,$y+260)
  $card=$bmp.GetPixel($x+170,$y+260)
  Write-Output ("pos=({0},{1}) pad_lum={2}({3},{4},{5}) card_lum={6}({7},{8},{9})" -f $x,$y,[int]($pad.R*0.299+$pad.G*0.587+$pad.B*0.114),$pad.R,$pad.G,$pad.B,[int]($card.R*0.299+$card.G*0.587+$card.B*0.114),$card.R,$card.G,$card.B)
}

Write-Output "=== 移动窗口到各处，采样 padding(x+6,y+260) 与卡片中心(x+170,y+260) ==="
SampleAt 60 60        # 左上(白区)
SampleAt 680 250      # 屏幕中央
SampleAt 60 700       # 左下
SampleAt 1200 500     # 右侧
SampleAt 60 60        # 回到左上
$g.Dispose();$bmp.Dispose()
Write-Output "DONE"
