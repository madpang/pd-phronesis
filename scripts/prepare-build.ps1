#! /usr/bin/env pwsh -NoProfile
<#$
	@file: prepare-build.ps1

	@brief: Prepare for building HTML artifacts from the text manuscripts.

	@note: 
	- This script should be executed on the working branch, which has *contents* folder.
	- This script should be called from the root of the repository.

	@author: madpang

	@date: [created: 2025-06-01, updated: 2026-01-20]
#>

$kWorkspace = "workspace"
$kContents = "contents"
$kArtifacts = "artifacts"
$artifactsDir = Join-Path $kWorkspace $kArtifacts
$oldIndexFile = Join-Path $kWorkspace "deployed-post-index.txt"
$hotIndexFile = Join-Path $artifactsDir "post-index.txt"

# if contents directory does not exist, abort
if (-not (Test-Path $kContents)) {
	Write-Error "[ERROR  ] Contents directory does not exist."
	exit 1
}

# If workspace directory does not exist, abort
if (-not (Test-Path $kWorkspace)) {
	Write-Error "[ERROR  ] Workspace does not exist."
	exit 1
}
if (Test-Path $artifactsDir) {
	Remove-Item -Path $artifactsDir -Recurse -Force
}
New-Item -Path $artifactsDir -ItemType Directory | Out-Null

Write-Host "[INFO   ] Scanning current post database..."
$currentPostList = Get-ChildItem $kContents -Directory | Where-Object { $_.Name -match '^(?<tag>[A-Z]{2})_(?<key>\d{4}_\d{2}_\d{2}_[a-z])$' } | ForEach-Object {
	$contentFile = Join-Path $kContents $_.Name ($_.Name + ".txt")
	if (Test-Path $contentFile) {
		$key = $Matches['key']
		$name = $_.Name
		$version = $null
		# Extract the version info. of the post
		foreach($line in [System.IO.File]::ReadLines($contentFile)) {
			if ($line -match '^`{3}$') {
				# only read as far as the header ends
				break
			} elseif ($line -match '^@version:\s*(\d+\.\d+\.\d+)\s*$') {
				$version = $Matches[1]
			} else {
				continue
			}
		}
		if ($version) {
			# collect the entry
			@{
				"Key" = $key
				"Name" = $name
				"Version" = $version
			}
		} # else do nothing
	}
}

# If the list is not empty, sort it by key and write to the index file
$newRecords = @()
if ($currentPostList) {
	# Keep as objects for processing
	$newRecords += $currentPostList | Sort-Object -Property "Key"
	# Write to file in string format
	$newRecords | ForEach-Object { "$( $_['Name'] )`t$( $_['Version'] )" } | Set-Content -Path $hotIndexFile -Encoding utf8
	Write-Host "=> Found $($currentPostList.Count) post(s)."
} else {
	Write-Host "=> No valid posts found."
	return
}

Write-Host "[INFO   ] Checking previous post records..."
$oldPostList = (Test-Path $oldIndexFile) ? (
	Get-Content -Path $oldIndexFile -Encoding utf8 | Where-Object {
		$_ -match '^(?<tag>[A-Z]{2})_(?<key>[0-9]{4}_[0-9]{2}_[0-9]{2}_[a-z])[\t\s]+(?<ver>\d+\.\d+\.\d+)$'
	} | ForEach-Object {
		@{
			"Key" = $Matches['key']
			"Name" = $Matches['tag'] + "_" + $Matches['key']
			"Version" = $Matches['ver']
		}
	}
) : @()

$oldRecords = @()
if ($oldPostList) {
	# Sort the previous posts by key
	$oldRecords += $oldPostList | Sort-Object -Property "Key"
	Write-Host "=> Previous records found."
} else {
	Write-Host "=> No previous post records found."
}
	
# === Main Processing ===
Write-Host "[INFO   ] Building post artifacts..."

# --- Determine new/update/delete actions
$newPostList = @()
$updatedPostList = @()
$deletedPostList = @()
$i = 0
$j = 0
while (($i -lt $oldRecords.Count) -and ($j -lt $newRecords.Count)) {
	$oldRecord = $oldRecords[$i]
	$newRecord = $newRecords[$j]
	# @note: Key is sorted and comparable.
	if ($oldRecord['Key'] -eq $newRecord['Key']) {
		if ($oldRecord['Version'] -eq $newRecord['Version']) {
			Write-Host "=> Skipping unchanged post $($oldRecord['Name'])"
		} else {
			Write-Host "=> Updating modified post $($newRecord['Name'])"
			$updatedPostList += $newRecord['Name']
		}
		$i++
		$j++
	} elseif ($oldRecord['Key'] -lt $newRecord['Key']) {
		Write-Host "=> Deleting post $($oldRecord['Name'])"
		$deletedPostList += $oldRecord['Name']
		$i++
	} else { # $oldRecord['Key'] > $newRecord['Key']
		Write-Host "=> Adding new post $($newRecord['Name'])"
		$newPostList += $newRecord['Name']
		$j++
	}
}

# Remaining old items are deletions
while ($i -lt $oldRecords.Count) {
	Write-Host "=> Removing deleted post $($oldRecords[$i]['Name'])"
	$deletedPostList += $oldRecords[$i]['Name']
	$i++
}

# Remaining new items are additions
while ($j -lt $newRecords.Count) {
	Write-Host "=> Adding new post $($newRecords[$j]['Name'])"
	$newPostList += $newRecords[$j]['Name']
	$j++
}

# --- Export the new/update/delete lists

$newPostList | Set-Content -Path (Join-Path $kWorkspace "posts-to-create.txt") -Encoding utf8

$updatedPostList | Set-Content -Path (Join-Path $kWorkspace "posts-to-update.txt") -Encoding utf8

$deletedPostList | Set-Content -Path (Join-Path $kWorkspace "posts-to-delete.txt") -Encoding utf8

Write-Host "[INFO   ] Finished post preparation."
Write-Host "=>  New post(s): $($newPostList.Count), Updated post(s): $($updatedPostList.Count), Deleted post(s): $($deletedPostList.Count)"

exit 0
