#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-deploy.ps1

	@brief: Deploy built artifacts from `tmp-ws/artifacts/` to `artifacts/` (for gh-pages branch).

	@details: Syncs the exported HTMLs and post-index.txt, and removes deleted posts.

	@note:
	- This script should be executed on the deployment branch, which contains the artifacts directory.
	- This script should be called from the root of the repository.

	@author: madpang

	@date: [created: 2025-06-03, updated: 2026-01-20]
#>

$kWorkspace = "workspace"
$kArtifacts = "artifacts"

$artifactsSourceDir = Join-Path $kWorkspace $kArtifacts
$artifactsDeployDir = Join-Path "public" $kArtifacts
$deletedListFile = Join-Path $kWorkspace "posts-to-delete.txt"

# If the source artifacts directory does not exist, abort
if (-not (Test-Path $artifactsSourceDir)) {
	Write-Host "[ERROR  ] Artifacts source directory does not exist: $artifactsSourceDir"
	exit 1
}

# If the deployment artifacts directory does not exist, create it
if (-not (Test-Path $artifactsDeployDir)) {
	New-Item -Path $artifactsDeployDir -ItemType Directory | Out-Null
}

# Copy new/updated HTML files from workspace/artifacts/ to public/artifacts/
Get-ChildItem -Path $artifactsSourceDir -Directory | ForEach-Object {
	Copy-Item -Path $_.FullName -Destination $artifactsDeployDir -Force -Recurse
}
# Overwrite `artifacts/post-index.txt`.
Copy-Item -Path (Join-Path $artifactsSourceDir "post-index.txt") -Destination (Join-Path $artifactsDeployDir "post-index.txt") -Force

# Remove deleted posts from artifacts/
if (Test-Path $deletedListFile) {
	$deletedList = Get-Content $deletedListFile -Encoding utf8
	foreach ($item in $deletedList) {
		$artifactPath = Join-Path $artifactsDeployDir $item
		if (Test-Path $artifactPath) {
			Remove-Item -Path $artifactPath -Recurse -Force
		}
	}
}

Write-Host "[INFO   ] Finished deployment of artifacts."
