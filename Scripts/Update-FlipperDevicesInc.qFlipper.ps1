if ($Env:GITHUB_TOKEN) {
    Write-Host 'GITHUB_TOKEN detected'
    $gitToken = ${Env:GITHUB_TOKEN}
}
else {
    Write-Host 'GITHUB_TOKEN not detected'
    exit 1
}

$url = ${Env:WebsiteURL}
$wingetPackage = ${Env:PackageName}

$versionDirectoryUrl = "https://update.flipperzero.one/qFlipper/directory.json"


$versionDirectory = Invoke-RestMethod -Uri $versionDirectoryUrl 
$latestVersionDirectory = ($versionDirectory.channels | Where-Object id -eq "release").versions.version
$latestVersionUrl = (($versionDirectory.channels | Where-Object id -eq "release").versions.files | Where-Object { ($_.target -eq "windows/amd64") -and ($_.type -eq "installer") }).url

$prMessage = "Update version: $wingetPackage version $latestVersionDirectory"

$ghVersionURL = "https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/$($wingetPackage.Substring(0, 1).ToLower())/$($wingetPackage.replace(".","/"))/$latestVersion/$wingetPackage.yaml"
$ghCheckURL = "https://github.com/microsoft/winget-pkgs/blob/master/manifests/$($wingetPackage.Substring(0, 1).ToLower())/$($wingetPackage.replace(".","/"))/"


# Check if package is already in winget
$ghCheck = Invoke-WebRequest -Uri $ghCheckURL -Method Head -SkipHttpErrorCheck 
if ($ghVersionCheck.StatusCode -eq 404) {
    Write-Output "Packet not yet in winget. Please add new Packet manually"
    exit 1
} 

$ghVersionCheck = Invoke-WebRequest -Uri $ghVersionURL -Method Head -SkipHttpErrorCheck  

#$foundMessage, $textVersion, $separator, $wingetVersions = winget search --id $wingetPackage --source winget --versions

if ($ghVersionCheck.StatusCode -eq 200) {
    Write-Output "Latest version of $wingetPackage $latestVersion is already present in winget."
    exit 0
}
else {
    # Check for existing PRs
    $ExistingOpenPRs = gh pr list --search "$($wingetPackage) $($latestVersion) in:title draft:false" --state 'open' --json 'title,url' --repo 'microsoft/winget-pkgs' | ConvertFrom-Json
    $ExistingMergedPRs = gh pr list --search "$($wingetPackage) $($latestVersion) in:title draft:false" --state 'merged' --json 'title,url' --repo 'microsoft/winget-pkgs' | ConvertFrom-Json

    $ExistingPRs = @($ExistingOpenPRs) + @($ExistingMergedPRs)        
    if ($ExistingPRs.Count -gt 0) {
        Write-Output "$foundMessage"
        $ExistingPRs | ForEach-Object {
            Write-Output "Found existing PR: $($_.title)"
            Write-Output "-> $($_.url)"
        }
    }
    elseif ($ghCheck -eq 200) {
        Invoke-WebRequest https://aka.ms/wingetcreate/latest -OutFile wingetcreate.exe
        .\wingetcreate.exe update $wingetPackage -s -v $latestVersionDirectory -u "$latestVersionUrl" --prtitle $prMessage -t $gitToken
    }
    else { 
        Write-Output "$foundMessage"
        Write-Output "No existing PRs found. Check why wingetcreate has not run."
    }
}
