# Disk Image to Docker Converter

[![Docker Build Status](https://img.shields.io/docker/build/your_dockerhub_username/your_image_name.svg)](https://hub.docker.com/r/your_dockerhub_username/your_image_name/) <!-- Optional: Add if you publish to Docker Hub -->

## What is this?

Ever wanted to run the software from a Raspberry Pi (or other device) disk image inside a Docker container? This tool makes it easy!

It takes a raw disk image file (like the `.img` file you flash onto an SD card) and extracts the main Linux filesystem from it, packaging it into a minimal Docker image.

## Why use it?

*   **Migrate Services:** Easily move services running on a physical device (like a Raspberry Pi) into a containerized environment.
*   **Run Legacy Systems:** Containerize older systems or specific OS configurations from disk images.

## How to Use

1.  **Prerequisites:** Make sure you have Docker installed and running.
2.  **Place Image:** Put your disk image file (e.g., `my-pi-image.img`) in the same directory as the `Dockerfile`.
3.  **Build the Docker Image:** Open your terminal in this directory and run the build command:

    ```bash
    docker build --build-arg IMG_PATH=./my-pi-image.img -t my-extracted-image .
    ```

    *   **Replace `./my-pi-image.img`** with the path (or URL) to *your* disk image file.
    *   *(Optional)* If the main Linux filesystem isn't the second partition (which is common for Raspberry Pi), add `--build-arg PARTITION_NUM=<number>` (e.g., `--build-arg PARTITION_NUM=1`).
    *   **Replace `my-extracted-image`** with the name you want to give your new Docker image.

4.  **Run the Container:** Once the build finishes, you can run your new container:

    ```bash
    docker run -it --rm my-extracted-image
    ```

    This will start the container using a `systemctl` replacement script, which attempts to start the services defined within the original image's filesystem (like `/etc/systemd/system/`).

## Important Notes

*   **Not a Full VM:** This creates a container, not a virtual machine. The original operating system's kernel is *not* used; it runs on your host's Linux kernel.
*   **Hardware:** Software inside the container that relies on specific hardware (like Raspberry Pi GPIO pins) will likely not work.
*   **`systemctl` Replacement:** This tool includes a script that mimics `systemctl` to try and start services. It works for many common services but might not handle very complex systemd units perfectly.
