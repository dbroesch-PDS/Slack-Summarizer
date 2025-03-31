# Slack-Summarizer

A collection of scripts that use Goose to generate and send summaries of Slack channels directly to your Slack DM.

## Features

- Generates daily summaries of specified Slack channels
- Organizes content into Key Discussions, Updates & Announcements, and Action Items
- Uses emojis for better visual organization
- Sends formatted digest directly to your Slack DM
- Configurable channel list and user targeting

## Directory Structure

```
Slack-Summarizer/
├── scripts/
│   └── slack_channel_summary.sh    # Main script for generating summaries
├── logs/
│   └── channel_summaries/          # Directory for storing generated digests
│       └── daily_channel_digest.txt # Most recent digest
└── README.md
```

## Usage

1. Configure the script by setting your email at the top of the script:
   ```bash
   USER_EMAIL="your.email@squareup.com"
   ```

2. Add or modify channels in the CHANNELS array:
   ```bash
   CHANNELS=(
       "CHANNEL_ID:channel-name"
       # Add more channels as needed
   )
   ```

3. Run the script:
   ```bash
   ./scripts/slack_channel_summary.sh
   ```

The script will:
- Generate summaries for each configured channel
- Save the digest to `logs/channel_summaries/daily_channel_digest.txt`
- Send the formatted digest to your Slack DM

## Summary Format

Each channel summary includes:
- **Key Discussions**: 3-4 main topics discussed
- **Updates & Announcements**: Important updates shared in the channel
- **Action Items**: Tasks, follow-ups, and pending actions

The summary uses various emojis to indicate different types of information:
- 🚨 `:alert:` for urgent items
- 📅 `:calendar:` for scheduled events
- ✅ `:white_check_mark:` for completed items
- ⌛ `:hourglass:` for deadlines
- 📈 `:chart_with_upwards_trend:` for metrics/data
- And many more...

## Requirements

- Goose CLI installed and configured
- Slack access with appropriate permissions
- Bash shell environment