---
file: README.txt
author: [madpang, claude]
date: [created: 2025-02-22, updated: 2026-11-01]
---

# pd-phronesis

**pd-phronesis** is a self-contained framework for blog site building, in a bare-bones, minimalistic style, using HTML, CSS, and JavaScript, without any 3rd party static site generation scaffold.

## Repository structure

The following ASCII graph depicts the structure of this repo.:
``` tree
pd-phronesis
|- README.txt            # *this* doc
|- README.md             # symlink --> README.txt
|- build-post.ps1        # executable script to build a single blog post
|- commons/              # common resources, to be deployed
|  |- fonts/
|  |- images/
|  |- styles/
|  |- scripts/
|- install-tools.ps1     # executable script to install the necessary tools
|- tools
|  |- mmd2html/          # submodule of custom text converter
|- tickets.txt           # issue tracker, progress log
```

## Usage

The build workflow is **PowerShell** based and uses the `mmd2html` converter.

To build a HTML post from a plain text file:
``` cmd
./build-post.ps1 <path-to-output.html> <path-to-input.txt>
```
Note, it is recommended to use absolute path for input and output.

## Additional notes

### Prerequisites

- PowerShell 7+
- The `mmd2html` executable in `PATH`, installed by `install-tools.ps1` to `$HOME/.local/bin/` from the latest GitHub release (Linux x86_64 only).

If `mmd2html` is not found, `build-post.ps1` runs `install-tools.ps1`, which asks for confirmation (y/N), and then retries with the installed executable.

The submodule is NOT needed to build posts; it is only needed to if you want to build `mmd2html` from source.

### Install mmd2html

``` cmd
./install-tools.ps1 [<install-dir>]
```
The install dir defaults to `$HOME/.local/bin`.

### Build mmd2html from source

Initialize the submodules first:
``` cmd
git submodule update --init
```

Then build the submodule *mmd2html* (note, it ships a Docker image definition with the GraalVM toolchain):
``` bash
./tools/mmd2html/.devcontainer/build.sh
docker run --rm -v "$PWD/tools/mmd2html:/mnt/datastore/cowork/20_repo/mmd2html" -w /mnt/datastore/cowork/20_repo/mmd2html mmd2html-dev:latest ./gradlew nativeCompile
```

## License info.

The CSS and JavaScript files are free to use, modify, and distribute.

[IBM Plex](https://www.ibm.com/plex/) series fonts are used as the primary typefaces.
It is an open-source font family, and can be obtained from [GitHub](https://github.com/IBM/plex).
