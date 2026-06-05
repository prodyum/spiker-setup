$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$repository = 'hasan-ozdemir/spiker-packages'
$assetName = 'spiker-setup.exe'
$releaseApiUrl = "https://api.github.com/repos/$repository/releases/latest"
$userAgent = 'spiker-install'
$originalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

function Write-Info {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[Spiker] $Message"
}

function Get-SafeInstallDirectory {
    $tempRoot = [System.IO.Path]::GetTempPath()
    if ([string]::IsNullOrWhiteSpace($tempRoot)) {
        throw 'Temp klasörü bulunamadı.'
    }

    $tempRootFull = [System.IO.Path]::GetFullPath($tempRoot)
    $directoryName = 'spiker-setup-' + ([Guid]::NewGuid().ToString('N'))
    $installDirectory = Join-Path $tempRootFull $directoryName
    $installDirectoryFull = [System.IO.Path]::GetFullPath($installDirectory)

    if (-not $installDirectoryFull.StartsWith($tempRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Güvenli olmayan temp yolu: $installDirectoryFull"
    }

    New-Item -Path $installDirectoryFull -ItemType Directory -Force | Out-Null
    return $installDirectoryFull
}

function Remove-SafeInstallDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    $tempRootFull = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    $leaf = Split-Path -Path $pathFull -Leaf

    if (-not $pathFull.StartsWith($tempRootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not $leaf.StartsWith('spiker-setup-', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Güvenli olmayan temizlik yolu: $pathFull"
    }

    Remove-Item -LiteralPath $pathFull -Recurse -Force -ErrorAction Stop
}

function Invoke-GitHubRequest {
    param([Parameter(Mandatory = $true)][string]$Uri)

    Invoke-RestMethod -Uri $Uri -Headers @{
        Accept = 'application/vnd.github+json'
        'User-Agent' = $userAgent
    }
}

function Get-LatestSetupAsset {
    Write-Info 'En son Spiker kurulum yayını aranıyor...'
    $release = Invoke-GitHubRequest -Uri $releaseApiUrl
    if ($null -eq $release.assets) {
        throw 'GitHub yayınında indirilebilir dosya bulunamadı.'
    }

    $asset = @($release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1)
    if ($asset.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$asset[0].browser_download_url)) {
        throw "En son GitHub yayınında $assetName bulunamadı."
    }

    $digestProperty = $asset[0].PSObject.Properties['digest']
    $digest = if ($null -ne $digestProperty) { [string]$digestProperty.Value } else { '' }

    return [pscustomobject]@{
        ReleaseName = [string]$release.name
        ReleaseTag = [string]$release.tag_name
        DownloadUrl = [string]$asset[0].browser_download_url
        Size = [int64]$asset[0].size
        Digest = $digest
    }
}

function Save-SetupAsset {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Asset,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $uri = [System.Uri]$Asset.DownloadUrl
    if ($uri.Scheme -ne 'https') {
        throw "Güvenli olmayan indirme adresi: $($Asset.DownloadUrl)"
    }

    Write-Info "İndiriliyor: $($Asset.ReleaseTag)"
    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.Headers['User-Agent'] = $userAgent
        $webClient.DownloadFile($Asset.DownloadUrl, $Destination)
    }
    finally {
        $webClient.Dispose()
    }

    $downloaded = Get-Item -LiteralPath $Destination
    if ($downloaded.Length -le 0) {
        throw 'Kurulum dosyası boş indirildi.'
    }

    if ($Asset.Size -gt 0 -and $downloaded.Length -ne $Asset.Size) {
        throw "Kurulum dosyası boyutu beklenenden farklı. Beklenen=$($Asset.Size), indirilen=$($downloaded.Length)."
    }

    if (-not [string]::IsNullOrWhiteSpace($Asset.Digest) -and $Asset.Digest.StartsWith('sha256:', [System.StringComparison]::OrdinalIgnoreCase)) {
        $expectedHash = $Asset.Digest.Substring('sha256:'.Length).ToUpperInvariant()
        $actualHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "SHA256 doğrulaması başarısız. Beklenen=$expectedHash, indirilen=$actualHash."
        }
    }

    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
        Unblock-File -LiteralPath $Destination -ErrorAction SilentlyContinue
    }
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
catch {
}

$installDirectory = $null
try {
    $installDirectory = Get-SafeInstallDirectory
    $setupPath = Join-Path $installDirectory $assetName
    $asset = Get-LatestSetupAsset

    Save-SetupAsset -Asset $asset -Destination $setupPath

    Write-Info 'Kurulum başlatılıyor. Kurulum penceresini takip edin.'
    $process = Start-Process -FilePath $setupPath -WorkingDirectory $installDirectory -WindowStyle Normal -Wait -PassThru
    $exitCode = if ($null -ne $process.ExitCode) { [int]$process.ExitCode } else { 0 }

    if ($exitCode -ne 0) {
        throw "Spiker kurulumu $exitCode çıkış koduyla sonlandı."
    }

    Write-Info 'Spiker kurulumu tamamlandı.'
}
finally {
    $ProgressPreference = $originalProgressPreference
    if ($null -ne $installDirectory) {
        try {
            Write-Info 'Geçici kurulum dosyaları temizleniyor...'
            Remove-SafeInstallDirectory -Path $installDirectory
            Write-Info 'Geçici dosyalar temizlendi.'
        }
        catch {
            Write-Warning "Geçici kurulum klasörü temizlenemedi: $installDirectory. $($_.Exception.Message)"
        }
    }
}
