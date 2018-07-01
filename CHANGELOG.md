# Change Log
This log only covers the highlights.  If you need granular change detail, please
pull up the SCM log and/or code diff between releases (where available).

### 2018 Version
Finished debugging.  Copied, expanded, and reformatted documentation from old
sources, converted to Markdown, and added tests.  Ported SCM from private Git
repo (Bitbucket) to public (GitHub).

### 2017 Version
Refactoring objective turned into a complete rewrite.  Jenkins support is
implicit rather than explicit (and no longer mandatory).  Ported SCM from
Mercurial to Git; abandoned history.

### 2016 Version
Added intrinsic Jenkins support; automatic release version tracking and
incrementing; and pre-defined variables:
  * build box OS
  * build box arch
  * builder identity
  * Changelog-compatible date generation

### 2011 Version
Major expansion to enable templating spec files.  Later extended template
handling to additional files (namely init.d scripts but the engine works on any
text file with appropriate markup).  Ported SCM from MSSCC to Mercurial;
abandoned commit history (no way to port).

### 2003 Version
Modular code rework.  Functionally the same but no longer one monolithic file.

### 2002 Version
Builds all indicated projects when passed a directory containing helpers
matching a given file-name pattern.  Added to MSSCC for versioning.

### 2001 Version
Project origination as a trivial helper script that merely assisted with kicking
off the `rpmbuild` command with repetitive command-line arguments fed from a
directory of helpers (pre-defined arguments passed into the main script).
