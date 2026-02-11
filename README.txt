``` header
@file: pd-phronesis/README.txt
@author: madpang
@date: [created: 2025-02-22, updated: 2026-02-11]
```

# pd-phronesis

This is a self-contained framework for blog site building, in a bare-bones, minimalistic style, using HTML, CSS, and JavaScript, without any 3rd party static site generation scaffold.

## Organization

This repository includes a single submodule:
- `tools/mmd2html`: the plain text → HTML converter used by the build scripts.

The folder structure of the project is as follows:
``` tree
.
|- README.md         # symlink --> README.txt
|- README.txt
|- tickets.txt       # issue tracker, progress log
|- commons/          # common resources, to be deployed
|  |- fonts/
|  |- images/
|  |- styles/
|  |- scripts/
|- tools
|  |- mmd2html/      # [submodule] custom plain text markup to HTML converter
|- build-post.ps1    # script to build a single blog post
```

## Usage

The build workflow is **PowerShell**-based and uses the `mmd2html` converter.

To build a HTML post from a plain text file:
``` powershell
pwsh -NoProfile ./build-post.ps1 <path-to-output.html> <path-to-input.txt>
```
Note, it is recommended to use absolute path.

## Additional notes

### Prerequisites

- PowerShell 7+
- Java (required to run the converter JAR)
- The submodule `mmd2html` being initialized and JAR being built (see its README for more details).

### Initialize submodules

``` powershell
git submodule update --init --recursive
```

## License info.

The CSS and JavaScript files are free to use, modify, and distribute.

[IBM Plex](https://www.ibm.com/plex/) series fonts are used as the primary typefaces.
It is an open-source font family, and can be obtained from [GitHub](https://github.com/IBM/plex).
