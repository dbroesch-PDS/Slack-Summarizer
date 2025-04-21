#!/bin/bash

# slack_channel_summary.sh
# Script to generate daily Slack channel summaries and send via Slack DM

# User configuration
USER_SLACK_ID="U043PMG1U1H"  # Parameterized user Slack ID

# Channel configurations - add channels here as "channel_id:channel_name" pairs
declare -a CHANNELS
CHANNELS=(
    # "C059PJAVBME:acquiring-sponsored"
    "C06HW9QMDGA:block-ds-core"
    #"C024LVDTA85:block-ds-leads"
    # "C056M8HPMJS:block-finops-team"
    "C01M8LL6M0S:cash-finplat-announce"
   # "C08B4SU0HNZ:cash-pds-core"
    "C08KNCL13U5:block-finplat-leads"
    # "C037B8GFDQX:finplat-pds"
    # "C044J31A7G8:proj-dps-x-block"
)

# Configuration
HOURS=24  # Default to 24 hours
OUTPUT_DIR="$HOME/slack-summarizer/logs/channel_summaries"
DATE_HEADER=$(date "+%A, %B %d, %Y - %I:%M %p")
DAILY_DIGEST="$OUTPUT_DIR/daily_channel_digest.json"

# Get user's DM channel ID from their Slack ID
get_dm_channel_id() {
    local DM_CHANNEL_ID
    DM_CHANNEL_ID=$(goose run -t "Using the slack__get_my_channels tool, find the direct message channel ID for user $USER_SLACK_ID and only return the channel ID." | grep -o 'D[A-Z0-9]\{8\}')
    
    if [ -z "$DM_CHANNEL_ID" ]; then
        echo "Error: Could not find DM channel for user $USER_SLACK_ID"
        return 1
    fi
    
    echo "$DM_CHANNEL_ID"
}

# Function to format bullet points
format_bullet_points() {
    local content="$1"
    # Convert each line to a properly formatted bullet point without dash
    echo "$content" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "• ${line}"
        fi
    done | tr '\n' '\n'
}

# Function to create a section block with context
create_section_block() {
    local title="$1"
    local content="$2"
    echo "{
        \"type\": \"section\",
        \"text\": {
            \"type\": \"mrkdwn\",
            \"text\": \"*🔹 *${title}* 🔹*\" 
        }
    },
    {
        \"type\": \"section\",
        \"text\": {
            \"type\": \"mrkdwn\",
            \"text\": \"*${content}*\" 
        }
    }"
}

# Function to create a divider block
create_divider_block() {
    echo '{
        "type": "divider"
    }'
}

# Function to create a header block
create_header_block() {
    local text="$1"
    echo "{
        \"type\": \"header\",
        \"text\": {
            \"type\": \"plain_text\",
            \"text\": \"🔔 *${text}* 🔔\",
            \"emoji\": true
        }
    }"
}

# Function to generate summary for a single channel
generate_channel_summary() {
    local CHANNEL_ID=$1
    local CHANNEL_NAME=$2
    local TEMP_SUMMARY=$(mktemp)
    
    echo "Generating summary for #${CHANNEL_NAME} channel..."
    
    # Create the prompt that will generate our summary
    PROMPT="Using the slack__get_channel_messages tool, get messages from channel $CHANNEL_ID (limit: 100) and create a concise summary of the last $HOURS hours of activity. DO NOT include any messages that are older than 7 days from now, even if the HOURS parameter is larger. If a message is more than 7 days old, ignore it completely. Format the response as follows:

Key Discussions:
[List 3-4 main topics from messages within the last 7 days only, one per line, keep each line concise and clear]

Updates & Announcements:
[List important updates from messages within the last 7 days only, one per line, keep each line concise and clear]

Action Items:
[List action items from messages within the last 7 days only, one per line, keep each line concise and clear]

If there are no messages within the last 7 days, state that explicitly in each section."

    # Run goose with the prompt and save to temp file
    goose run -t "$PROMPT" > "$TEMP_SUMMARY"

    # Clean up the output: Remove ANSI color codes
    sed -i '' -e 's/\x1b\[[0-9;]*m//g' "$TEMP_SUMMARY"
    
    # Parse the sections
    local KEY_DISCUSSIONS=$(sed -n '/Key Discussions:/,/Updates & Announcements:/p' "$TEMP_SUMMARY" | sed '1d;$d')
    local UPDATES=$(sed -n '/Updates & Announcements:/,/Action Items:/p' "$TEMP_SUMMARY" | sed '1d;$d')
    local ACTION_ITEMS=$(sed -n '/Action Items:/,$p' "$TEMP_SUMMARY" | sed '1d')
    
    # Format bullet points
    KEY_DISCUSSIONS=$(format_bullet_points "$KEY_DISCUSSIONS")
    UPDATES=$(format_bullet_points "$UPDATES")
    ACTION_ITEMS=$(format_bullet_points "$ACTION_ITEMS")
    
    # Create JSON blocks for the channel
    echo "[" >> "$DAILY_DIGEST"
    create_header_block "#${CHANNEL_NAME}" >> "$DAILY_DIGEST"
    echo "," >> "$DAILY_DIGEST"
    create_section_block "💬 Key Discussions" "$KEY_DISCUSSIONS" >> "$DAILY_DIGEST"
    echo "," >> "$DAILY_DIGEST"
    create_section_block "📢 Updates & Announcements" "$UPDATES" >> "$DAILY_DIGEST"
    echo "," >> "$DAILY_DIGEST"
    create_section_block "✅ Action Items" "$ACTION_ITEMS" >> "$DAILY_DIGEST"
    echo "," >> "$DAILY_DIGEST"
    create_divider_block >> "$DAILY_DIGEST"
    echo "]" >> "$DAILY_DIGEST"

    # Clean up
    rm "$TEMP_SUMMARY"
}

# Function to send digest via Slack DM
send_digest_to_slack() {
    local DM_CHANNEL_ID=$1
    local TEMP_CMD=$(mktemp)
    local HAS_NEW_MESSAGES=$2
    
    echo "Sending digest to Slack..."
    
    if [ "$HAS_NEW_MESSAGES" = "0" ]; then
        # Create a message for no new updates
        cat > "$TEMP_CMD" << EOL
Using the slack__post_message tool, send this message to user $USER_SLACK_ID:

{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🔔 📰 Daily Channel Digest 🔔",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*📅 *${DATE_HEADER}* *"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*📊 *Monitoring ${#CHANNELS[@]} channels* *"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*✨ No new messages since last summary ✨*"
            }
        }
    ]
}
EOL
    else
        # Create the Slack message command with Block Kit format for new messages
        cat > "$TEMP_CMD" << EOL
Using the slack__post_message tool, send this message to user $USER_SLACK_ID:

{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🔔 📰 Daily Channel Digest 🔔",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*📅 *${DATE_HEADER}* *"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*📊 *Monitoring ${#CHANNELS[@]} channels* *"
            }
        },
        {
            "type": "divider"
        },
        $(cat "$DAILY_DIGEST" | sed '1d')
    ]
}
EOL
    fi
    
    # Send the message
    goose run -t "$(cat $TEMP_CMD)"
    rm "$TEMP_CMD"
}

# Main execution
echo "Starting channel summaries for ${#CHANNELS[@]} channels..."

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Initialize the digest file with an empty array
echo "[]" > "$DAILY_DIGEST"

# Track if we found any new messages
HAS_NEW_MESSAGES=0

# Process each channel
for channel in "${CHANNELS[@]}"; do
    # Split the channel string into ID and name
    IFS=':' read -r channel_id channel_name <<< "$channel"
    if generate_channel_summary "$channel_id" "$channel_name"; then
        HAS_NEW_MESSAGES=1
    fi
done

echo "All channel summaries completed!"
echo "Daily digest saved to: $DAILY_DIGEST"

# Get DM channel ID and send digest
DM_CHANNEL_ID=$(get_dm_channel_id)
if [ -n "$DM_CHANNEL_ID" ]; then
    send_digest_to_slack "$DM_CHANNEL_ID" "$HAS_NEW_MESSAGES"
    echo "Digest sent to user $USER_SLACK_ID via Slack"
else
    echo "Error: Could not determine DM channel for user $USER_SLACK_ID"
fi