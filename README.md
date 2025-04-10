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

3. Configure the time window for message summaries (default is 24 hours):
   ```bash
   HOURS=24  # Set to 168 for a 7-day window
   ```

4. Run the script:
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

Note: The script will only include messages from the last 7 days, regardless of the HOURS parameter setting. This ensures that summaries remain relevant and focused on recent activity.

The summary uses various emojis to indicate different types of information:
- 🚨 `:alert:` for urgent items
- 📅 `:calendar:` for scheduled events
- ✅ `:white_check_mark:` for completed items
- ⌛ `:hourglass:` for deadlines
- 📈 `:chart_with_upwards_trend:` for metrics/data
- And many more...

## Requirements

### Core Requirements
- Bash shell environment
- Git (for cloning this repository)
- Access to Square's Slack workspace
- Appropriate Slack permissions for channels you want to summarize

### Slack MCP Installation

The Slack MCP (Message Control Protocol) is required for this script to interact with Slack. You can install it using either the GUI or CLI method:

#### GUI Installation (Recommended for Most Users)
1. Follow the installation guide in the [Goose Slack MCP Setup Document](https://docs.google.com/document/d/1BXDlgcvaFw3nuTx541-oKIN8cilZn9MPztOVpfTDtUE/edit?tab=t.0)
2. This guide provides step-by-step instructions with screenshots for:
   - Creating a Slack App
   - Configuring necessary permissions
   - Setting up OAuth tokens
   - Installing the MCP through Goose's GUI

#### CLI Installation (For Advanced Users)
1. For command-line installation, follow the instructions in the [MCP Slack Repository](https://github.com/squareup/mcp/tree/main/mcp_slack#readme)
2. This method provides:
   - Detailed configuration steps
   - Manual token setup
   - Advanced customization options
   - Command-line based installation process

### Post-Installation
After installing the Slack MCP:
1. Verify installation by running a test command through Goose
2. Ensure you have the necessary Slack scopes enabled:
   - channels:read
   - channels:history
   - chat:write
   - users:read
   - users:read.email
3. Configure your authentication tokens in the MCP configuration