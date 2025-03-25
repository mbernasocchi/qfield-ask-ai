const apis = [
  {
    // Anthropic API is the default
    name: "Anthropic",
    url: "https://api.anthropic.com/v1/messages",
    models: [
      "claude-3-7-sonnet-latest",
      "claude-3-5-sonnet-latest",
      "claude-3-5-haiku-latest",
    ],
  },
  {
    name: "OpenAI",
    url: "https://api.openai.com/v1/chat/completions",
    models: ["gpt-4o", "gpt-4.5", "gpt-3.5-turbo"],
  },
  {
    name: "Infomaniak",
    url: "https://api.infomaniak.com/1/ai/102849/openai/chat/completions",
    models: ["llama3", "whisper", "reasoning"],
  },
];
