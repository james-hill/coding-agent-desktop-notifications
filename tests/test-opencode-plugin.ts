#!/usr/bin/env npx tsx
//
// Test harness for the OpenCode Slack notifications plugin.
// Mocks the OpenCode client and fires events to verify behavior.
//
// Usage: npx tsx test-opencode-plugin.ts

import { readFileSync } from "fs"
import { join, basename } from "path"
import { homedir } from "os"

// --- Inline the plugin code to avoid @opencode-ai/plugin dependency ---

interface Config {
  enabled: boolean
  webhookUrl: string
  debounceSeconds: number
}

function loadConfig(): Config {
  const config: Config = {
    enabled: false,
    webhookUrl: "",
    debounceSeconds: 10,
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
        case "debounce_seconds": config.debounceSeconds = parseInt(value, 10) || 10; break
      }
    }
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code !== "ENOENT") {
      console.error(`[slack-notifications] Failed to read config: ${err}`)
    }
  }

  config.webhookUrl = process.env.SLACK_NOTIFICATIONS_WEBHOOK ?? config.webhookUrl
  return config
}

function truncate(text: string, max = 300): string {
  return text.length > max ? text.slice(0, max) + "..." : text
}

const EVENT_ICONS: Record<string, string> = {
  "session.idle": "\u2705",
  "session.error": "\u274C",
  "permission.asked": "\u{1F4AC}",
}
const DEFAULT_ICON = "\u{1F514}"

async function notify(title: string, event: any, client?: any) {
  const config = loadConfig()
  if (!config.enabled || !config.webhookUrl) {
    console.log(`  [skip] notifications disabled or no webhook URL`)
    return
  }
  try {
    const project = basename(process.cwd())
    const sessionId = event.properties?.sessionId ?? event.properties?.sessionID
    const icon = EVENT_ICONS[event.type] ?? DEFAULT_ICON

    let summary = ""
    if (client && sessionId) {
      try {
        const response = await client.session.messages({ path: { id: sessionId } })
        const messages = response.data ?? response
        for (let i = messages.length - 1; i >= 0; i--) {
          const msg = messages[i]
          if (msg.role !== "assistant") continue
          const textParts = (msg.parts ?? []).filter((p: any) => p.type === "text")
          if (textParts.length > 0) {
            summary = truncate(textParts.map((p: any) => p.text ?? "").join("\n").trim())
            break
          }
        }
      } catch (err) {
        console.error(`  [warn] Failed to fetch session messages: ${err}`)
      }
    }

    const blocks: any[] = [
      { type: "divider" },
      {
        type: "section",
        fields: [
          { type: "mrkdwn", text: `${icon}  *${title}*` },
          { type: "mrkdwn", text: project },
        ],
      },
    ]

    if (summary) {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: `\`\`\`${summary}\`\`\`` }
      })
    }

    const resp = await fetch(config.webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: `${title}: ${project}`,
        blocks,
      })
    })
    if (!resp.ok) {
      throw new Error(`Slack returned ${resp.status}: ${await resp.text()}`)
    }
    console.log(`  [ok] sent`)
  } catch (err) {
    console.error(`  [error] ${err}`)
  }
}

// --- Mock client ---

const mockClient = {
  session: {
    messages: async ({ path }: { path: { id: string } }) => ({
      data: [
        { role: "user", parts: [{ type: "text", text: "Fix the login bug" }] },
        { role: "assistant", parts: [{ type: "text", text: "I've fixed the login bug by updating the session validation logic in auth.ts." }] },
      ]
    })
  },
  app: {
    log: async ({ body }: { body: any }) => {
      console.log(`  [log] ${body.level}: ${body.message}`)
    }
  }
}

// --- Test runner ---

interface TestCase {
  name: string
  title: string
  event: any
  useClient: boolean
}

const tests: TestCase[] = [
  {
    name: "session.idle (task completed)",
    title: "OpenCode Session Completed",
    event: { type: "session.idle", properties: { sessionId: "test-123" } },
    useClient: true,
  },
  {
    name: "session.error",
    title: "OpenCode Error",
    event: { type: "session.error", properties: { sessionId: "test-456" } },
    useClient: true,
  },
  {
    name: "permission.asked",
    title: "OpenCode Needs Permission",
    event: { type: "permission.asked", properties: { sessionId: "test-789" } },
    useClient: true,
  },
  {
    name: "session.idle without session messages",
    title: "OpenCode Session Completed",
    event: { type: "session.idle", properties: {} },
    useClient: false,
  },
  {
    name: "unknown event type (fallback icon)",
    title: "OpenCode Unknown Event",
    event: { type: "some.new.event", properties: {} },
    useClient: false,
  },
]

async function run() {
  const config = loadConfig()
  console.log(`Config: enabled=${config.enabled}, webhook=${config.webhookUrl ? "set" : "NOT SET"}, debounce=${config.debounceSeconds}s`)
  console.log("")

  const filter = process.argv[2]

  for (const test of tests) {
    if (filter && !test.name.includes(filter)) continue

    console.log(`--- ${test.name} ---`)
    await notify(test.title, test.event, test.useClient ? mockClient : undefined)
    console.log("")

    // Small delay between sends to keep them in order in Slack
    await new Promise(r => setTimeout(r, 500))
  }

  console.log("Done.")
}

run()
