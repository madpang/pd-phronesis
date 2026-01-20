#! /usr/bin/env pwsh -NoProfile
<#$
	@file: build-export.ps1

	@brief: Build HTML artifacts for newly added and updated posts, output to `tmp-ws/artifacts/`.

	@details: This script combines the new and updated post lists, then for each post, it will call the `build-post.ps1` script to generate the HTML artifact.

	@note:
	- This script should be executed on the working branch, which has contents folder.
	- This script should be called from the root of the repository.

	@author: madpang

	@date: [created: 2025-06-03, updated: 2026-01-20]
#>

$kWorkspace = "workspace"
$kContents = "contents"

# if contents directory does not exist, abort
if (-not (Test-Path $kContents)) {
	Write-Error "[ERROR  ] Contents directory does not exist."
	exit 1
}

# If export artifacts directory does not exist, abort
$artifactsExportDir = Join-Path $kWorkspace "artifacts"
if (-not (Test-Path $artifactsExportDir)) {
	Write-Host "[ERROR  ] Artifacts export directory has not been properly set up: $artifactsExportDir"
	exit 1
}

# === Main Processing ===

$mTemplateFile = Join-Path "commons" "templates" "post-template.html"
$mBuildScript = "./build-post.ps1"

$newListFile = Join-Path $kWorkspace "posts-to-create.txt"
$updatedListFile = Join-Path $kWorkspace "posts-to-update.txt"

# Read new and update lists
$newPostList = @()
$updatePostList = @()
if (Test-Path $newListFile) {
	$newPostList = Get-Content $newListFile -Encoding utf8
}
if (Test-Path $updatedListFile) {
	$updatePostList = Get-Content $updatedListFile -Encoding utf8
}

$waitingList = $newPostList + $updatePostList
foreach ($item in $waitingList) {
	$path2content = Join-Path $kContents $item ($item + ".txt")
	$path2artifact = Join-Path $artifactsExportDir $item ($item + ".html")
	# Call external script to build the post
	& $mBuildScript $path2artifact $path2content $mTemplateFile
	if ($LASTEXITCODE -ne 0) {
		Write-Host "[ERROR  ] Failed to build post: $item"
		exit $LASTEXITCODE
	}
}

Write-Host "[INFO   ] Finished exporting post artifacts to $artifactsExportDir"
