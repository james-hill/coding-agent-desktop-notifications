#!/usr/bin/env python3
import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path

DEBOUNCE_FILE = Path("/tmp/agent-notify-debounce")
CONFIG_PATH = Path(
    os.environ.get(
        "AGENT_NOTIFY_CONFIG",
        Path.home() / ".config" / "slack-notifications" / "notify.yaml",
    )
)

DEFAULTS = {
    "enabled": False,
    "webhook_url": "",
    "debounce_seconds": 10,
}


def load_config() -> dict:
    # Hand-rolled YAML parsing to avoid requiring PyYAML (not in stdlib)
    config = dict(DEFAULTS)
    if CONFIG_PATH.is_file():
        for line in CONFIG_PATH.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = re.match(r"^(\w+)\s*:\s*(.+)$", line)
            if not match:
                continue
            key, value = match.group(1), match.group(2).strip().strip("'\"")
            if key == "enabled":
                config["enabled"] = value.lower() != "false"
            elif key == "webhook_url":
                config["webhook_url"] = value
            elif key == "debounce_seconds":
                try:
                    config["debounce_seconds"] = int(value)
                except ValueError:
                    pass

    # Env vars override config
    if env_url := os.environ.get("SLACK_NOTIFICATIONS_WEBHOOK"):
        config["webhook_url"] = env_url
    if env_debounce := os.environ.get("SLACK_NOTIFICATIONS_DEBOUNCE_SECONDS"):
        try:
            config["debounce_seconds"] = int(env_debounce)
        except ValueError:
            pass

    return config


def read_stdin() -> str:
    if not sys.stdin.isatty():
        try:
            return sys.stdin.read()
        except Exception:
            return ""
    return ""


def truncate(text: str, max_len: int = 300) -> str:
    return text[:max_len] + "..." if len(text) > max_len else text


def cancel_debounce() -> None:
    """Invalidate any pending notification by writing a fresh token."""
    DEBOUNCE_FILE.write_text(f"cancel-{os.getpid()}-{time.time_ns()}")


def debounce(delay: int) -> bool:
    """Write a unique token, sleep, then check if we're still the latest invocation."""
    if delay <= 0:
        return True
    token = f"{os.getpid()}-{time.time_ns()}"
    DEBOUNCE_FILE.write_text(token)
    time.sleep(delay)
    try:
        return DEBOUNCE_FILE.read_text() == token
    except FileNotFoundError:
        return False


EVENT_ICONS = {
    "Stop": "\u2705",          # white check mark
    "Notification": "\U0001f4ac",  # speech balloon
}
DEFAULT_ICON = "\U0001f514"    # bell


def send_slack(
    webhook_url: str, title: str, project: str, hook_event: str = "", detail: str = ""
) -> None:
    icon = EVENT_ICONS.get(hook_event, DEFAULT_ICON)
    blocks = [
        {"type": "divider"},
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"{icon}  *{title}*"},
                {"type": "mrkdwn", "text": project},
            ],
        },
    ]
    if detail:
        blocks.append(
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"```{truncate(detail)}```"},
            }
        )

    payload = json.dumps({"text": f"{title}: {project}", "blocks": blocks}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    urllib.request.urlopen(req, timeout=10)


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--cancel":
        cancel_debounce()
        return

    config = load_config()
    if not config["enabled"]:
        return

    webhook_url = config["webhook_url"]
    if not webhook_url:
        print("Error: No webhook URL configured", file=sys.stderr)
        sys.exit(1)

    stdin_data = read_stdin()
    title = sys.argv[1] if len(sys.argv) > 1 else "Agent Needs Input"

    # Extract fields from hook JSON
    project_dir = ""
    detail = ""
    hook_event = ""
    if stdin_data.strip():
        try:
            hook_data = json.loads(stdin_data)
            project_dir = hook_data.get("cwd", "")
            hook_event = hook_data.get("hook_event_name", "")
            if hook_event == "Stop":
                detail = hook_data.get("last_assistant_message", "")
            elif hook_event == "Notification":
                detail = hook_data.get("message", "")
        except json.JSONDecodeError:
            pass

    project = os.path.basename(project_dir or os.getcwd())

    # Fork to background so the hook returns immediately
    if os.fork() != 0:
        return  # Parent exits right away

    # Child: detach from parent session
    os.setsid()

    if not debounce(config["debounce_seconds"]):
        return

    send_slack(webhook_url, title, project, hook_event=hook_event, detail=detail)


if __name__ == "__main__":
    main()
