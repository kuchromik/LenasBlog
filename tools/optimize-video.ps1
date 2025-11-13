<#
Optimize a video for web delivery using ffmpeg.

Usage:
  1. Install ffmpeg and ensure it's in your PATH: https://ffmpeg.org/
  2. Place the original video in the repo (e.g. static/images/IMG_0322.mp4)
  3. Run this script from the repository root (PowerShell):
     .\tools\optimize-video.ps1 -Source "static/images/IMG_0322.mp4" -OutDir "static/videos"

What the script does:
  - Creates `OutDir` if missing
  - Generates two optimized files:
      * MP4 (H.264 baseline/main with AAC audio, 1080p max, 2500k bitrate)
      * WebM (VP9) as fallback
  - Names output files like IMG_0322.web-optimized.mp4 and IMG_0322.webm

Adjust bitrates/resolution as needed.
#>

param(
    [string]$Source = "static/images/IMG_0322.mp4",
    [string]$OutDir = "static/videos",
    [int]$MaxWidth = 1920,
    [int]$VideoBitrate = 2500, # in kbps
    [int]$AudioBitrate = 128, # in kbps
    [int]$PosterTimeSec = 1 # second into the video to grab poster frame
)

if (!(Test-Path $Source)) {
    Write-Error "Source file not found: $Source"
    exit 1
}

if (!(Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$base = [System.IO.Path]::GetFileNameWithoutExtension($Source)
$mp4Out = Join-Path $OutDir "$base.web-optimized.mp4"
$webmOut = Join-Path $OutDir "$base.web-optimized.webm"

Write-Host "Generating optimized MP4 -> $mp4Out"
$ffmpegMp4 = "ffmpeg -y -i `"$Source`" -vf \"scale='min($MaxWidth,iw)':-2\" -c:v libx264 -preset slow -profile:v high -level 4.0 -b:v ${VideoBitrate}k -maxrate ${VideoBitrate}k -bufsize ${VideoBitrate}k -c:a aac -b:a ${AudioBitrate}k -movflags +faststart `"$mp4Out`""
Write-Host $ffmpegMp4
Invoke-Expression $ffmpegMp4

Write-Host "Generating optimized WebM (VP9) -> $webmOut"
$ffmpegWebm = "ffmpeg -y -i `"$Source`" -vf \"scale='min($MaxWidth,iw)':-2\" -c:v libvpx-vp9 -b:v ${VideoBitrate}k -crf 30 -c:a libopus -b:a ${AudioBitrate}k `"$webmOut`""
Write-Host $ffmpegWebm
Invoke-Expression $ffmpegWebm

# Extract a poster frame (JPEG) at the requested time into the output directory
$posterOut = Join-Path $OutDir "$base.poster.jpg"
Write-Host "Extracting poster frame ($PosterTimeSec s) -> $posterOut"
$ffmpegPoster = "ffmpeg -y -ss ${PosterTimeSec} -i `"$Source`" -frames:v 1 -q:v 2 `"$posterOut`""
Write-Host $ffmpegPoster
Invoke-Expression $ffmpegPoster

Write-Host "Done. Place the following sources in your HTML/Markdown video tag (mp4 first, webm fallback):"
Write-Host "  <video controls poster=\"/images/IMG_0331.jpg\">"
Write-Host "    <source src=\"/videos/$($base).web-optimized.mp4\" type=\"video/mp4\">"
Write-Host "    <source src=\"/videos/$($base).web-optimized.webm\" type=\"video/webm\">"
Write-Host "  </video>"
