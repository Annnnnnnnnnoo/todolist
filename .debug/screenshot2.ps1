Add-Type -AssemblyName System.Drawing
# 缩小全屏到 600 宽
$src=[System.Drawing.Image]::FromFile("D:\todolist\.debug\fullscreen.png")
$w=600;$h=[int]($src.Height*($w/$src.Width))
$bmp=[System.Drawing.Bitmap]::new($w,$h)
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src,0,0,$w,$h)
$bmp.Save("D:\todolist\.debug\fullscreen_small.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$bmp.Dispose();$src.Dispose()
# 窗口图直接缩放
$src2=[System.Drawing.Image]::FromFile("D:\todolist\.debug\window.png")
$bmp2=[System.Drawing.Bitmap]::new(340,520)
$g2=[System.Drawing.Graphics]::FromImage($bmp2)
$g2.DrawImage($src2,0,0,340,520)
$bmp2.Save("D:\todolist\.debug\window_small.png",[System.Drawing.Imaging.ImageFormat]::Png)
$g2.Dispose();$bmp2.Dispose();$src2.Dispose()
Write-Output "DONE"
