param(
    [Parameter(Mandatory=$true)]
    [int]$durationInMinutes
)

function Save-Audio {
    param(
        [int]$durationInMinutes,
        [string]$basePath
    )

    Write-Host "Starting audio recording for $durationInMinutes minutes"

    $durationInSeconds = $durationInMinutes * 60
    

    # create the year directory
    $year = Get-Date -Format "yyyy"
    $yearDirectory = New-Item -ItemType Directory -Path $basePath -Name $year -Force

    # get the new file name to be used
    $timestamp = Get-Date -Format "yyyy-MM-dd HH mm"
    $outputFilename = Join-Path $yearDirectory -ChildPath "$timestamp.mp3"

    # check file does not exist
    if (Test-Path $outputFilename) {
        Write-Error "File $outputFilename already exists..appending seconds to the timestamp"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH mm ss"
        $outputFilename = Join-Path $yearDirectory -ChildPath "$timestamp.mp3"
    }

    #Write-Output "hello world" | Out-File $outputFilename

    try {
        ffmpeg.exe -f dshow -i audio='@device_cm_{33D9A762-90C8-11D0-BD43-00A0C911CE86}\wave_{6D571688-9276-4659-A6F1-7EECE08AE476}' -filter:a "volume=30dB" -t $durationInSeconds $outputFilename
    } catch {
        Write-Error "Error during recording. Please check your audio device settings and try again."
        exit 1
    }
}

function Sync-to-S3 {
    param(
        [string]$basePath
    )

    $bucketName = "s3://nbc-services-internal-audio"

    Write-Host "Syncing files to S3 bucket $bucketName"

    aws s3 sync --dryrun $basePath $bucketName 
}

function Remove-Old-Files {
    param (
        [string]$basePath,
        [int]$ageInDays
    )
    
    Write-Host "Removing files older than $ageInDays days"
  
    Get-ChildItem $basePath -Recurse -File | Where-Object CreationTime -lt (Get-Date).AddDays(-1 * $ageInDays) #| Remove-Item -Force
}



$basePath = "C:/Users/dante-recorder/recordings"

Write-Host "Script starting with base path $basePath"

Save-Audio -basePath $basePath -durationInMinutes $durationInMinutes
Sync-to-S3 -basePath $basePath
Remove-Old-Files -basePath $basePath -ageInDays 30

Write-Host "Script complete"