# Stage 1: Extract the filesystem using guestfish
# Use full debian image for kernel packages
FROM debian:bookworm AS extractor

# Install guestfish (libguestfs-tools).
# Note: This package and its dependencies can be relatively large.
# Using --no-install-recommends to try and minimize size.
RUN apt-get update && \
# Also install the kernel image needed by libguestfs/supermin.
    apt-get install --no-install-recommends -y libguestfs-tools linux-image-amd64 && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# Argument for the disk image path relative to the build context
ARG IMG_PATH=./image.img
# Argument for the partition number to extract (defaulting to 2)
# guestfish typically enumerates disks as /dev/sda, /dev/sdb, etc.
# and partitions as /dev/sda1, /dev/sda2, etc.
ARG PARTITION_NUM=2

# Copy the disk image into the build stage
COPY ${IMG_PATH} /image.img

# Create the directory to hold the extracted root filesystem
RUN mkdir /extracted_rootfs

# Extract the filesystem using guestfish
# --ro: Open the image read-only.
# -a /image.img: Add the image file for guestfish to operate on.
# -m /dev/sdaN:/ : Mount the specified partition (assuming /dev/sda) to the root inside guestfish.
# tar-out / - : Create a tar archive of the mounted filesystem's root and pipe it to stdout.
# | tar -xf - -C /extracted_rootfs : Pipe the tar stream to the host 'tar' command to extract into /extracted_rootfs.
# Note: guestfish might require certain kernel capabilities. BuildKit usually handles this well.
# If issues arise, building with elevated privileges might be needed, but try without first.
RUN set -ex; \
    PARTITION_DEVICE="/dev/sda${PARTITION_NUM}"; \
    echo "Attempting to extract partition ${PARTITION_DEVICE} from /image.img using guestfish..."; \
    LIBGUESTFS_DEBUG=1 guestfish --ro -a /image.img -m ${PARTITION_DEVICE}:/ tar-out / - | tar -xf - -C /extracted_rootfs; \
    echo "Extraction complete."; \
    # Clean up the image file
    rm /image.img; \
    echo "Cleanup complete."

# Stage 2: Create the final runnable image
FROM scratch

# Copy the extracted filesystem from the extractor stage
COPY --from=extractor /extracted_rootfs /

# Set a default command (interactive shell)
# Remember: The original init system (e.g., systemd) will not run automatically.
CMD ["/bin/bash"]

# --- Optional Enhancements ---
# EXPOSE 80 443
# HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1
# USER appuser
# WORKDIR /app
# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]