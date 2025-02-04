#!/bin/sh

##Configuration and first run
CONFIG_FILE="$HOME/.sh-evidence.conf"

# Default configuration and create config file if it is not created
FONT="DejaVuSansMono.ttf"
PADDING="20,20,20,20"
DROP_SHADOW="false"
EVIDENCE_DIR="$HOME/Documents/sh-evidence"

function has_drop_shadow {
  if [[ "$*" == *"--drop-shadow"* ]]; then
    echo "true"
  else
    echo "false"
  fi
}

create_config_file() {
    echo "FONT=$FONT" > $CONFIG_FILE
    echo "PADDING=$PADDING" >> $CONFIG_FILE
    echo "DROP_SHADOW=$DROP_SHADOW" >> $CONFIG_FILE
    echo "EVIDENCE_DIR=$EVIDENCE_DIR" >> $CONFIG_FILE
    mkdir -p "$EVIDENCE_DIR"
}

load_config() {
    config_file="$HOME/.sh-evidence.conf"
    if [ -f "$config_file" ]; then
        . "$config_file"
    fi

    # Set default values if not defined in the config file
    : "${FONT:=DejaVuSansMono.ttf}"
    : "${PADDING:=50}"
    : "${DROP_SHADOW:=0}"

    config="{"
    config="$config\"font\": \"$FONT\","
    config="$config\"padding\": $PADDING,"
    config="$config\"drop_shadow\": $DROP_SHADOW"
    config="$config}"

    echo "$config"
}

if [ ! -f "$CONFIG_FILE" ]; then
    create_config_file
else
    config="$(load_config)"
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PYTHON_CMD="python3"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PYTHON_CMD="python3"
elif [[ "$OSTYPE" == "cygwin" ]]; then
    PYTHON_CMD="python"
elif [[ "$OSTYPE" == "msys" ]]; then
    PYTHON_CMD="python"
elif [[ "$OSTYPE" == "win32" ]]; then
    PYTHON_CMD="python"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

##Application Functionality
# Read command from the piped input
CMD=$(cat)

# Extract the command used without parameters
LAST_CMD="$(echo "$CMD" | awk '{print $1}')"

# Define the log file and screenshot file names
DATE_SUFFIX="$(date +%Y%m%d%H%M%S)"
LOGFILE="$EVIDENCE_DIR/${LAST_CMD}_${DATE_SUFFIX}.log"
IMAGE="$EVIDENCE_DIR/${LAST_CMD}_${DATE_SUFFIX}.png"

OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
    printf "\$ %s\n" "$CMD" >> "$LOGFILE"
    eval "$CMD" >> "$LOGFILE" 2>&1
    cat "$LOGFILE"
elif [[ "$OS" == "Linux" ]]; then
    printf "\$ %s\n" "$CMD" >> "$LOGFILE"
    script -c "$CMD" -q /dev/null >> "$LOGFILE" 2>&1
    cat "$LOGFILE"
else
    echo "Unsupported operating system"
    exit 1
fi


# Check if --drop-shadow flag is used
DROP_SHADOW=$(has_drop_shadow "$@")

# Generate an image from the log file using the Python script
if [[ "$*" == *"--drop-shadow"* ]]; then
  $PYTHON_CMD text_to_image.py "$LOGFILE" "$IMAGE" --drop-shadow
else
  $PYTHON_CMD text_to_image.py "$LOGFILE" "$IMAGE"
fi
