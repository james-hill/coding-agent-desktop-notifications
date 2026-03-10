import type { Plugin } from "@opencode-ai/plugin"
import { readFileSync } from "fs"
import { join, basename } from "path"
import { homedir } from "os"

interface Config {
  enabled: boolean
  webhookUrl: string
}

function loadConfig(): Config {
  const config: Config = {
    enabled: true,
    webhookUrl: "",
  }

  const configPath =
    process.env.AGENT_NOTIFY_CONFIG ??
    join(homedir(), ".config", "slack-notifications", "notify.yaml")

  try {
    const content = readFileSync(configPath, "utf-8")
    for (const line of content.split("\n")) {
      if (/^\s*#/.test(line) || !line.trim()) continue
      const match = line.match(/^(\w+)\s*:\s*(.+)$/)
      if (!match) continue
      const [, key, raw] = match
      const value = raw.replace(/^['"]|['"]$/g, "").trim()
      switch (key) {
        case "enabled": config.enabled = value !== "false"; break
        case "webhook_url": config.webhookUrl = value; break
      }
    }
  } catch {
    // Config file not found, use defaults
  }

  // Env vars override config
  config.webhookUrl = process.env.WEBHOOK_URL ?? config.webhookUrl

  return config
}

async function notify(title: string, event: any, client?: any) {
  const config = loadConfig()
  if (!config.enabled || !config.webhookUrl) return
  try {
    const project = basename(process.cwd())
    await fetch(config.webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: `${title}: ${project}`,
        blocks: [{
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*${title}*\n*Project:* ${project}\n*Session ID:* ${event.properties?.sessionId ?? "unknown"}\n*Files modified:* ${event.properties?.filesModified ?? "unknown"}`
          }
        }]
      })
    })
  } catch (err) {
    if (client) {
      await client.app.log({
        body: {
          service: "slack-notifications",
          level: "error",
          message: `Failed to send notification: ${err}`,
        },
      })
    }
  }
}

export const SlackNotificationsPlugin: Plugin = async ({ client }) => {
  await client.app.log({
    body: {
      service: "slack-notifications",
      level: "info",
      message: "Plugin initialized",
    },
  })
  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.idle":
          await notify("OpenCode Session Completed", event, client)
          break
        case "session.error":
          await notify("OpenCode Error", event, client)
          break
        case "permission.asked":
          await notify("OpenCode Needs Permission", event, client)
          break
      }
    },
  }
}
