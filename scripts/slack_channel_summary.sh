#!/bin/bash

# slack_channel_summary.sh
# Script to generate daily Slack channel summaries and send via Slack DM

# User configuration
USER_EMAIL="dbroesch@squareup.com"  # Parameterized user email

# Channel configurations - add channels here as "channel_id:channel_name" pairs
declare -a CHANNELS
CHANNELS=(
    "C059PJAVBME:acquiring-sponsored"
    "C06HW9QMDGA:block-ds-core"
    "C024LVDTA85:block-ds-leads"
    "C056M8HPMJS:block-finops-team"
    "C01M8LL6M0S:cash-finplat-announce"
    "C08B4SU0HNZ:cash-pds-core"
    "C07JVEUCTJL:finplat-leads"
    "C037B8GFDQX:finplat-pds"
    "C044J31A7G8:proj-dps-x-block"
)

# Configuration
HOURS=24
OUTPUT_DIR="$HOME/slack-summarizer/logs/channel_summaries"
DATE_HEADER=$(date "+%A, %B %d, %Y - %I:%M %p")
DAILY_DIGEST="$OUTPUT_DIR/daily_channel_digest.txt"

# Get user's Slack user ID from their email
get_user_id() {
    local USER_ID
    USER_ID=$(goose run -t "Using the slack__get_user_by_email tool, get the Slack user ID for $USER_EMAIL and only return the ID." | grep -o 'U[A-Z0-9]\{8\}')
    echo "$USER_ID"
}

# Function to center text with a specific width
center_text() {
    local text="$1"
    local width=50  # Adjust this value to change the centering width
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# Function to generate summary for a single channel
generate_channel_summary() {
    local CHANNEL_ID=$1
    local CHANNEL_NAME=$2
    local TEMP_SUMMARY=$(mktemp)
    
    echo "Generating summary for #${CHANNEL_NAME} channel..."
    
    # Create the prompt that will generate our summary
    PROMPT="Using the slack__get_channel_messages tool, get messages from channel $CHANNEL_ID (limit: 100) and create a concise summary of the last 24 hours of activity. Format the response as follows:

*#${CHANNEL_NAME}*

:speech_balloon: *Key Discussions*
[List 3-4 main topics, indent each with 4 spaces and use • as bullet points. Add relevant emojis at the start of each point. Add a blank line after this section for spacing]

:loudspeaker: *Updates & Announcements*
[List important updates, indent each with 4 spaces and use • as bullet points. Add relevant emojis at the start of each point. Add a blank line after this section for spacing]

:clipboard: *Action Items*
[List action items, indent each with 4 spaces and use • as bullet points. Add relevant emojis at the start of each point]

Use relevant emojis such as:
:alert: for urgent items
:calendar: for scheduled events
:white_check_mark: for completed items
:hourglass: for deadlines
:people_holding_hands: for team-related items
:chart_with_upwards_trend: for metrics/data
:gear: for technical updates
:memo: for documentation
:rocket: for launches/deployments
:tools: for infrastructure
:handshake: for partnerships
:question: for open questions
:eyes: for monitoring/watching
:bell: for important notifications
:email: for communication items
:link: for dependencies
:dna: for data science specific items
:brain: for AI/ML related items"

    # Run goose with the prompt and save to temp file
    goose run -t "$PROMPT" > "$TEMP_SUMMARY"

    # Clean up the output:
    # 1. Remove ANSI color codes
    sed -i '' -e 's/\x1b\[[0-9;]*m//g' "$TEMP_SUMMARY"
    
    # 2. Extract just the content we want
    local CLEANED_SUMMARY=$(mktemp)
    
    # Add centered channel name and solid line
    printf "\n" > "$CLEANED_SUMMARY"
    center_text "*#${CHANNEL_NAME}*" >> "$CLEANED_SUMMARY"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" >> "$CLEANED_SUMMARY"
    
    # Extract the content sections
    sed -n '/^:speech_balloon:/,/^:brain:/p' "$TEMP_SUMMARY" >> "$CLEANED_SUMMARY"
    
    # Add separator before channel summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$DAILY_DIGEST"
    echo >> "$DAILY_DIGEST"  # Add a blank line after separator
    
    # Append cleaned summary to digest
    cat "$CLEANED_SUMMARY" >> "$DAILY_DIGEST"
    echo >> "$DAILY_DIGEST"  # Add a blank line after summary

    # Clean up
    rm "$TEMP_SUMMARY"
    rm "$CLEANED_SUMMARY"
}

# Function to send digest via Slack DM
send_digest_to_slack() {
    local USER_ID=$1
    local DIGEST_CONTENT
    DIGEST_CONTENT=$(cat "$DAILY_DIGEST")
    local TEMP_CMD=$(mktemp)
    
    echo "Sending digest to Slack..."
    
    # Create the Slack message command
    cat > "$TEMP_CMD" << EOL
Using the slack__post_message tool, send this message to @${USER_EMAIL%@*} (user ID: ${USER_ID}):

${DIGEST_CONTENT}

:end: End of Daily Digest
EOL
    
    # Send the message
    goose run -t "$(cat $TEMP_CMD)"
    rm "$TEMP_CMD"
}

# Main execution
echo "Starting channel summaries for ${#CHANNELS[@]} channels..."

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Create new digest file with header
cat > "$DAILY_DIGEST" << EOL
:newspaper: *DAILY CHANNEL DIGEST*
:calendar: ${DATE_HEADER}
:bar_chart: Monitoring ${#CHANNELS[@]} channels
EOL

# Process each channel
for channel in "${CHANNELS[@]}"; do
    # Split the channel string into ID and name
    IFS=':' read -r channel_id channel_name <<< "$channel"
    generate_channel_summary "$channel_id" "$channel_name"
done

echo "All channel summaries completed!"
echo "Daily digest saved to: $DAILY_DIGEST"

# Get user ID and send digest
USER_ID=$(get_user_id)
if [ -n "$USER_ID" ]; then
    send_digest_to_slack "$USER_ID"
    echo "Digest sent to $USER_EMAIL via Slack"
else
    echo "Error: Could not determine Slack user ID for $USER_EMAIL"
fi