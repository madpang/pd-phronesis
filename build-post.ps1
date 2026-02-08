#! /usr/bin/env pwsh -NoProfile
<#
	@file: pd-phronesis/build-post.ps1
	
	@brief: Build a single HTML post from the manuscript.

	@details:
	1. Read the template HTML file.
	2. Use the mmd2html tool to convert the source text to HTML, and insert it into the anchor point in the template.
	3. Write the output to the target HTML file.

	@note:
	- The template file path is hardcoded, since it is part of the framework.
	- In step [2], the mmd2html need a temporary output file to store the converted HTML content, which will be read back to insert into the template.
	- The temporary file will be placed alongside the target HTML file, with a ".tmp" suffix.
	- This script assumes path arguments do not contain spaces.
	- It is better to work with absolute paths.

	@author: madpang

	@date: [created: 2025-05-18, updated: 2026-02-08]
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,     # @output
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt       # @input
)

$isDebug = $true

# === Verify the tool path exists
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$toolPath = Join-Path -Path $scriptRoot -ChildPath 'tools/mmd2html/app/build/libs/mmd2html.jar'
if (-not (Test-Path $toolPath)) {
	@("HTML conversion tool not found.", "Expected converter path: $toolPath", "Make sure submodule is initialized.") -join [Environment]::NewLine | Write-Error
	exit -1
}

# === Verify the template file exists
$path2template = Join-Path -Path $scriptRoot -ChildPath 'templates/post-template.html'
if (-not (Test-Path $path2template)) {
	"Template file not found: $path2template" | Write-Error
	exit -3
}

# === Convert the source text to HTML

# --- Create the containing folder of the HTML post if it does not exist
$outputDir = Split-Path -Path $path2html -Parent
if (-not (Test-Path $outputDir)) {
	try {
		New-Item -ItemType Directory -Path $outputDir | Out-Null
	} catch {
		"Failed to create output directory: $outputDir" | Write-Error
		exit -4
	}
}

# --- Prepare temporary output file path
$path2converted = $path2html + ".tmp";

$cmd = @('java', '-jar', $toolPath, $path2txt, $path2converted) -join ' '

if ($isDebug) {
	@("[DEBUG] Converting source text to HTML:", "> $cmd") -join [Environment]::NewLine | Write-Host
}

# --- Invoke the conversion command
Invoke-Expression $cmd

$toolExitCode = $LASTEXITCODE
if ($toolExitCode -ne 0) {
	"Conversion failed with exit code $toolExitCode." | Write-Error
	exit $toolExitCode
}

if (-not (Test-Path $path2converted)) {
	"Conversion did not generate expected output file: $path2converted" | Write-Error
	exit -2
}

# === Assemble the final HTML file

$formattedLines = Get-Content -Path $path2converted -Encoding utf8

# --- Extract h1 heading (for display in the web browser tab)
$browserTabTitle = $null
foreach ($line in $formattedLines) {
	if ($line -match '<h1>(.*)</h1>') {
		$browserTabTitle = $Matches[1]
		break
	}
}

if (-not $browserTabTitle) {
	"Article must have a title." | Write-Error
	exit -10
}

# --- Read the template HTML file
$templateLines = Get-Content -Path $path2template -Encoding utf8

# --- Assemble the output HTML file
$authorInfo = "MadPang"
$inBlockComment = $false
$outputLines = @()
for ($ii = 0; $ii -lt $templateLines.Count; $ii++) {
	$line = $templateLines[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match '^<!--\s*(?<id>[@:\w]+)\s*$') {
		$inBlockComment = $true
		$id = $Matches['id']
		if ($id -eq '@ANCHOR:NULL') {
			$outputLines += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
		}
		continue
	}
	if ($line -match '^-->$') {
		$inBlockComment = $false
		continue
	}
	if ($inBlockComment) {
		# Skip the block comment
		continue
	}
	if ($line -match '^<!--\s*@ANCHOR:TITLE\s*-->$') {
		# Insert the title text into the anchor point
		$outputLines += "$browserTabTitle | $authorInfo"
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$outputLines += $formattedLines
		continue
	}

	# Add normal line to the output
	$outputLines += $line
}

# === Cleanup temporary files
if (Test-Path $path2converted) {
	if ($isDebug) {
		Write-Host "[DEBUG] Cleaning up temporary file: $path2converted"
	}
	Remove-Item -Path $path2converted
}

# === Write the output to HTML file
try {
	if ($isDebug) {
		"[DEBUG] Writing output HTML file: $path2html" | Write-Host
	}	
	Set-Content -Path $path2html -Value $outputLines -Encoding utf8
	exit 0
} catch {
	"Failed to write output file: $path2html" | Write-Error
	exit -5
}
