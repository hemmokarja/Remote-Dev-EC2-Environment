#!/bin/bash

wait_for_network_connectivity() {
  local retries=30
  local sleep_interval=5

  for ((i=1; i<=retries; i++)); do
    if ping -c1 google.com &>/dev/null; then
      echo "Network is up!"
      return 0
    else
      echo "Waiting for network... (attempt $i/$retries)"
      sleep $sleep_interval
    fi
  done

  echo "Network connection timed out after $retries attempts. Could not bootstrap " \
    "the dev instance with dev toolkit. Exiting."
  exit 1
}

source_bashrc() {
  # ubuntu's .bashrc starts with commands that prevent sourcing it within a shell script,
  # and this hack bypasses those constraints. For more, see this:
  # https://askubuntu.com/questions/64387/cannot-successfully-source-bashrc-from-a-shell-script
  eval "$(tail -n +10 $HOME/.bashrc)"
}

update_system() {
  echo "Updating system..."
  sudo apt update -y
  sudo apt upgrade -y
}

install_aws_cli() {
    echo "Installing AWS CLI for programmatic interaction with AWS..."
    
    echo "Installing dependencies..."
    sudo apt install -y unzip

    echo "Downloading AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    echo "Unzipping AWS CLI installer..."
    unzip awscliv2.zip

    echo "Installing AWS CLI..."
    sudo ./aws/install

    echo "Verifying AWS CLI installation..."
    if command -v aws > /dev/null 2>&1; then
      echo "AWS CLI installed successfully! Version:"
      aws --version
    else
      echo "AWS CLI installation failed or aws command not found."
    fi

    echo "Cleaning up..."
    rm -rf awscliv2.zip aws

    echo "AWS CLI installation complete!"
}

install_pyenv() {
  echo "Installing Pyenv for Python version management..."

  echo "Installing dependencies..."
  sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git

  echo "Cloning Pyenv repository..."
  git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv

  echo "Setting up environment for Pyenv..."

  echo '# Pyenv' >> $HOME/.bashrc
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.bashrc
  echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.bashrc
  echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> $HOME/.bashrc

  source_bashrc

  echo "Verifying Pyenv installation..."
  if command -v pyenv > /dev/null 2>&1; then
    
    echo "Pyenv installed successfully! Version:"
    pyenv --version

    echo "Installing Python 3.12 (this might take a while)..."
    pyenv install 3.12
    pyenv global 3.12

    echo "Python version:"
    python3 --version

    echo "Pyenv configured!"
  else
    echo "Pyenv installation failed or pyenv command not found."
  fi
}

install_poetry() {
  echo "Installing Poetry for virtual environment management..."

  curl -sSL https://install.python-poetry.org | python3 -

  echo '# Poetry' >> $HOME/.bashrc
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
  source_bashrc

  if command -v poetry > /dev/null 2>&1; then
    echo "Poetry installed successfully! Version:"
    poetry --version

    poetry config virtualenvs.in-project true
    poetry config virtualenvs.prefer-active-python true

    echo "Poetry configured!"
  else
    echo "Poetry installation failed or poetry command not found."
  fi
}

install_docker() {
  set -e
  # https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  apt-cache policy docker-ce
  sudo apt install -y docker-ce
  sudo usermod -aG docker ubuntu
  echo "Docker installed successfully!"
}

update_bash_prompt() {
    cat << 'EOF' >> $HOME/.bashrc
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1="\e[35m\u@\h (dev) \[\e[36m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\] \n> "
EOF
  echo "Bash prompt customized!"
}


wait_for_network_connectivity
update_system
install_aws_cli
install_pyenv
install_poetry
install_docker
update_bash_prompt

exit 0