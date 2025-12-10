FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

# Install system dependencies
RUN apt update \
    && apt install -y software-properties-common \
    && add-apt-repository ppa:ubuntuhandbook1/ffmpeg8

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    git \
    rsync \
    software-properties-common \
    sudo \
    unzip \
    libnvidia-decode-565-server \
    python3.12-full \
    python3-pip \
    ffmpeg \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && apt-get autoremove -y

# Create a non-root user
RUN groupadd -g 568 apps \
    && useradd apps -ms /bin/bash -u 568 -g 568 \
    && mkdir -p /home/apps/.local \
    && chown -R apps:apps /home/apps/.local

RUN mkdir -p /opt/venv \
    && chown -R 568:568 /opt/venv \
    && python3 -m venv /opt/venv

# Enable venv
ENV PATH="/opt/venv/bin:$PATH"

RUN chown -R 568:568 /opt/venv

# Install FFmpeg with CUDA/NVDEC support
# COPY scripts/install_ffmpeg_cuda.py /tmp/install_ffmpeg_cuda.py
# RUN python3.12 /tmp/install_ffmpeg_cuda.py --prefix /usr/local && rm /tmp/install_ffmpeg_cuda.py

USER apps

# Copy the wheel file and install it
COPY --chown=568:568 dist/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl /tmp/
RUN pip install /tmp/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl \
    && rm /tmp/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl

COPY . /app

# Install pip dependencies
# RUN python3.12 -m pip install -r requirements.txt

# Expose the port FastAPI runs on
EXPOSE 8000

# Set the working directory
WORKDIR /app

# Command to run the server.py script
# CMD ["python3.12", "server.py"]
CMD ["/bin/bash", "-c", "python3.12 -m pip install --no-warn-script-location -r install/requirements-base.txt; python3.12 -m pip install --no-warn-script-location -r install/requirements.txt; python3.12 server.py"]
