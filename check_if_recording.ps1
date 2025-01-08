if (Get-Process ffmpeg -ErrorAction SilentlyContinue) {
    $true
} else {
    $false
}