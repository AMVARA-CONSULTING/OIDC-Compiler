# Automating the Compilation and Installation of `mod_auth_openidc` Using Docker

The provided [entrypoint.sh](/entrypoint.sh) script and [docker-compose.yml](/docker-compose.yml) file automate the process of downloading, and compiling the [mod_auth_openidc](https://github.com/zmartzone/mod_auth_openidc) module for Apache HTTP Server. 

The script updates system packages, fetches the latest release of `mod_auth_openidc` from GitHub, installs necessary dependencies, compiles the module, and verifies the compilation. The [docker-compose.yml](/docker-compose.yml) file defines a service using the latest Apache HTTP Server image, mounts the script and output directory, and executes the script within the container. If successful, the compiled module is saved to the `dist` directory on the host.

## Prerequisites

- Docker: 
    Ensure Docker is installed on your system. You can download and install Docker from the [official Docker website](https://docs.docker.com/get-docker/).

## Uses
1. **Initialization:**
   - When `docker-compose up` is executed, Docker Compose starts the defined `apache` service, creating a container using the `httpd:latest` image.

2. **Script Execution:**
   - The container mounts the `entrypoint.sh` script and the `dist` directory from the host.
   - The working directory is set to `/code`, where the `entrypoint.sh` script is located.
   - The `entrypoint.sh` script is executed, performing all the steps to download, compile, and verify the `mod_auth_openidc` module.

3. **Compilation Output:**
   - If the compilation is successful, the compiled module (`mod_auth_openidc.so`) is placed in the `dist` directory on the host, making it available for further use or deployment.
<br>
<br>
<hr>

### Documentation of `entrypoint.sh`

The `entrypoint.sh` script performs the following steps:

1. **Setup the `dist` Directory:**
   - Determines and creates the `dist` directory relative to the script's location.

2. **Update System Packages and Install Basic Utilities:**
   - Updates the package list.
   - Installs basic utilities like `curl`, `jq`, `wget`, and `unzip`.

3. **Fetch Latest Release Version:**
   - Fetches the latest release information of `mod_auth_openidc` from GitHub ([GitHub API for releases](https://developer.github.com/v3/repos/releases/)).
   - Extracts the latest version number using `jq`.

4. **Generate and Download Source Code URL:**
   - Constructs the download URL for the source code based on the latest version.
   - Downloads the source code as a zip file to the `/tmp` directory.

5. **Install Compilation Dependencies:**
   - Installs various dependencies required for compiling `mod_auth_openidc` ([mod_auth_openidc dependencies](https://github.com/zmartzone/mod_auth_openidc#build)).

6. **Compile the `mod_auth_openidc` Module:**
   - Unzips the downloaded source code.
   - Changes the working directory to the unzipped source code folder.
   - Runs the `autogen.sh` script to generate the `configure` script.
   - Configures the build environment.
   - Compiles the source code using `make`.
   - Installs the compiled module.

7. **Verify the Compiled Module:**
   - Checks if the compiled module's version matches the expected version.
   - If successful, copies the compiled module to the `dist` directory and generates an MD5 checksum.
   - If the version check fails, it prints an error message and exits with a non-zero status.


### Documentation of  `docker-compose.yaml`

The `docker-compose.yaml` file defines a Docker Compose configuration for running the `entrypoint.sh` script in a Docker container. Here's a breakdown of its configuration:

1. **Services:**
   - Defines a single service named `apache`.

2. **Apache Service:**
   - Uses the latest `httpd` (Apache HTTP Server) image ([Docker Hub `httpd` image](https://hub.docker.com/_/httpd)).
   - Names the container `oidc_compiler`.
   - Maps the `entrypoint.sh` script from the host to the container in read-only mode.
   - Maps the `dist` directory from the host to the container with read-write permissions.
   - Sets the working directory to `/code` inside the container.
   - Executes the `entrypoint.sh` script using `bash` when the container starts.
