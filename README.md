# Dynamic Package Builder
This project extends the standard package specification file to enable dynamic
construction.  Doing so allows for external configuration, boilerplate sharing,
templates, and other dynamic content creation.  Extensible through contributed
functions, this project also enables you to easily integrate RPM building into
your own workflows so that you can deliver binary packages as part of your
routine build process.

## Coding For Fun
This project also serves as an example of some of bash's more interesting
capabilities as a programming language.  It demonstrates:

  * complex text file parsing and templating
  * recursive variable expansion
  * passing associative arrays as parameters to functions
  * restricting permissible values (via RegEx) for variable assignments
  * dynamic code inclusion
  * complex command-line parsing without using `getopt`
  * merging configuration from many sources with priorities

As such, this project will run only on bash 4.3 or later.  Fear not if you don't
have a sufficient version of bash.  It is reasonably simple to compile and
install a compatible version of bash from source to your build box or container.

# Usage
Synopsis:

	build-rpm-specs.sh [OPTIONS] [-- RPMBUILD_ARGS]

In the simplest use-case:

  1. For your project, place your RPM specification file(s) into a top-level
     SPECS subdirectory.
  2. From the top-level directory of your project, clone (submodule) this
     project and run `dynamic-package-builder/build-rpm-specs.sh` without any
	 arguments.
  3. Your binary and source packages will be written under the RPMS and SRPMS
     subdirectories of your project.

More complex uses might add an external configuration file for the package
specification.  Further complexity -- and centralization of common configuration
needs -- usually breaks the external configuration up into several imports,
some dynamic so that the specification file can be dynamically constructed from
organizational boilerplate files and shared settings.  No matter how complex the
package specification and its external templates and configuration files, you
would still likely just run `dynamic-package-builder/build-rpm-specs.sh` without
any arguments.

However, you can certainly pass any of the many supported parameters and flags
to this script should you:

  * opt not to store your package sources or specifications in top-level SOURCES
    and SPECS directories, respectively;
  * need to pass custom configuration to the `rpmbuild` command that you cannot
  * otherwise represent in your specification file;
  * control which packages (binary and source) are to be built;
  * customize how temporary workspace files are handled; or
  * otherwise control the behavior of this script.

See `build-rpm-specs.sh --help` for a detailed exploration of all capabilities.
See the tests for examples in varying degrees of complexity.

# Extensions
This project extends legacy package specification files by enabling variable
substitution from external sources as well as enabling external file injection.
It also enables external configuration files to perform dynamic value
construction for the variables employed by package specification files.

## Package Specification Files
Package specification files are extended by adding the following markup:

  1. ${:VAR_NAME} is a simple variable substitution.
  2. ${:VAR_NAME:=default} and ${:VAR_NAME:-default} are identical to
     ${:VAR_NAME} except that 'default' becomes the value when VAR_NAME is
     undefined or empty.
  3. ${@FILE_CONCAT} copies the content of FILE_CONCAT verbatim into the spec
     file.  Any variables or other file concatenations are processed.

Substitutions are performed recursively and repeatedly, allowing for late
definitions, simple or complex embedding, and even dynamic variable and file
name resolutions.

See `build-rpm-specs.sh --help SPECS` for more detail.

## Configuration Files
External configuration files allow for even more flexibility.  If you have
package specification file named my-project.spec, an optional external
configuraiton file named my-project.conf will be automatically loaded and
processed, if found in the same directory as the specification file.  These
feature-rich configuration files can dynamically populate the variables used
within your specification file.  Such features include:

  1. Flexible assignment operators -- your choice of "key=value", "key =
     value", "key:value", or "key: value" -- allowing your team to use
	 whichever style they are most comfortable with.
  2. Flexible whitespace handling, allowing for vertical alignment if desired.
  3. HEREDOC handling with optional indentation removal.
  4. Comments using the # symbol.
  5. Variable substitution.
  6. Multi-pass resolution, allowing variables to be used before they are
     defined.
  7. Include files, enabling multiple configuration files to be used to
     construct the whole configuration.
  8. Recursive variable resolution, enabling dynamic variable and file name
     construction.
  9. External command execution to resolve values at run-time.
  10. Read external file content as the value of a variable.
  11. Read values from environment variables.

See `build-rpm-specs.sh --help CONFIGS` for more detail.

## Contributed Functions
This project comes with some stock (example) contributed functions, including:

  * getReleaseNumberForVersion:  provides logic that can generate the next
    appropriate release number for a given package version.  This function
	tracks release numbers within a structured data file that is saved to a
	given directory.  The directory is subdivided by given package architecture
	and operating system.
  * getVersionFromFileName:  provides logic that can identify the version of a
    product from its file-name, provided the version number appears in the
	file-name in a reliable, identifiable way.
  * publishViaCopy:  provides logic that can copy all generated RPMs to a
    package repository directory that is accessible to the local file-system.
  * updateRepositoryMetadata:  provides logic that can generate or update
    RPM/yum repository metadata.

You can write and employ your own custom functions to further specialize the
handling of your specifications and better integrate this tool with your own
workflows and environments.

See `build-rpm-specs.sh --help CONTRIB` for more detail.
