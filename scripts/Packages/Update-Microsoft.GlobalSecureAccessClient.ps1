return [PSCustomObject]@{
  Version = Get-ProductVersionFromFile -WebsiteURL $WebsiteURL -VersionInfoProperty "ProductVersion"
  URLs = $WebsiteURL
}
