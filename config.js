const apis = [
  {
    // Anthropic API is the default
    name: "Anthropic",
    key_url: "https://console.anthropic.com/login?selectAccount=true&returnTo=%2Fsettings%2Fadmin-keys%3F",
    url: "https://api.anthropic.com/v1/messages",
    models: [
      "claude-sonnet-4-20250514",
      "claude-3-7-sonnet-latest",
      "claude-3-5-sonnet-latest",
      "claude-3-5-haiku-latest",
    ],
    headers: {
      "x-api-key": "%%API_KEY%%",
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
  },
  {
    name: "OpenAI",
    key_url: "https://platform.openai.com/api-keys",
    url: "https://api.openai.com/v1/chat/completions",
    models: ["gpt-4.1", "gpt-4o", "gpt-4.5", "gpt-3.5-turbo"],
    headers: {
      "Authorization": "Bearer %%API_KEY%%",
      "content-type": "application/json",
    },
  },
  //{
  //  name: "Infomaniak",
  //  key_url: "https://www.infomaniak.com/en/hosting/ai-tools",
  //  url: "https://api.infomaniak.com/1/ai/102849/openai/chat/completions",
  //  models: ["llama3", "whisper", "reasoning"],
  //  headers: {
  //    "Authorization": "Bearer %%API_KEY%%",
  //    "content-type": "application/json",
  //  },
  //},
];
