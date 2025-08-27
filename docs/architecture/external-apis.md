# External APIs

Based on the PRD requirements and component design, xPando integrates with several external services to provide comprehensive AI capabilities, blockchain functionality, and infrastructure services. Each integration includes proper authentication, error handling, and fallback mechanisms.

## OpenAI API

- **Purpose:** Access to GPT-4, GPT-3.5-turbo, and text-embedding models for diverse AI capabilities and knowledge synthesis
- **Documentation:** https://platform.openai.com/docs/api-reference
- **Base URL(s):** https://api.openai.com/v1
- **Authentication:** Bearer token via API key in Authorization header
- **Rate Limits:** 10,000 requests/minute for GPT-4, 3,500 requests/minute for GPT-3.5-turbo

**Key Endpoints Used:**
- `POST /chat/completions` - Chat-based AI interactions for knowledge processing
- `POST /embeddings` - Generate text embeddings for knowledge similarity matching
- `GET /models` - List available models and capabilities

**Integration Notes:** Circuit breaker pattern implemented with 3-retry limit and exponential backoff. Response caching via Redis for identical prompts within 1-hour window. Token usage tracked for cost optimization and XPD reward calculations.

```elixir
defmodule XPando.AI.Providers.OpenAI do
  @base_url "https://api.openai.com/v1"
  
  def chat_completion(messages, opts \\ []) do
    model = opts[:model] || "gpt-4"
    
    body = %{
      model: model,
      messages: messages,
      temperature: opts[:temperature] || 0.7,
      max_tokens: opts[:max_tokens] || 1000
    }
    
    case http_client().post("#{@base_url}/chat/completions", body, headers()) do
      {:ok, %{status: 200, body: response}} -> 
        track_token_usage(response["usage"])
        {:ok, response["choices"] |> List.first() |> get_in(["message", "content"])}
      {:error, reason} -> 
        {:error, reason}
    end
  end
  
  defp headers do
    [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]
  end
end
```

## Anthropic Claude API

- **Purpose:** Access to Claude 3.5 Sonnet and Claude 3 Haiku for advanced reasoning, code analysis, and ethical AI responses
- **Documentation:** https://docs.anthropic.com/claude/reference/
- **Base URL(s):** https://api.anthropic.com/v1
- **Authentication:** API key via x-api-key header
- **Rate Limits:** 1,000 requests/minute with 100,000 tokens/minute limit

**Key Endpoints Used:**
- `POST /messages` - Send messages to Claude for AI processing
- `POST /messages/stream` - Streaming responses for real-time interaction

**Integration Notes:** Specialized for complex reasoning tasks and ethical knowledge validation. Implements content safety filters and maintains conversation context for multi-turn knowledge synthesis sessions.

## Google AI (Gemini) API

- **Purpose:** Access to Gemini Pro and Gemini Pro Vision for multimodal AI capabilities and Google's knowledge base
- **Documentation:** https://ai.google.dev/api/rest
- **Base URL(s):** https://generativelanguage.googleapis.com/v1
- **Authentication:** API key via query parameter or Authorization header
- **Rate Limits:** 1,500 requests/minute with 1 million tokens/minute

**Key Endpoints Used:**
- `POST /models/gemini-pro:generateContent` - Generate text content for knowledge creation
- `POST /models/gemini-pro-vision:generateContent` - Process images and multimodal content

**Integration Notes:** Primary use for multimodal knowledge processing and integration with Google's vast knowledge sources. Fallback provider when OpenAI and Anthropic are unavailable.

## Solana RPC API

- **Purpose:** Blockchain interactions for XPD token management, wallet verification, and transaction processing
- **Documentation:** https://docs.solana.com/api/http
- **Base URL(s):** https://api.mainnet-beta.solana.com (production), https://api.devnet.solana.com (development)
- **Authentication:** None required for public endpoints
- **Rate Limits:** 100 requests/10 seconds for free tier, higher limits for premium

**Key Endpoints Used:**
- `POST /` with `getAccountInfo` - Verify wallet addresses and token balances
- `POST /` with `sendTransaction` - Submit XPD token transfer transactions
- `POST /` with `getTokenAccountsByOwner` - Query token holdings for reward distribution

**Integration Notes:** All blockchain operations queued through Oban jobs for reliability. Transaction confirmations monitored with exponential backoff retry logic. Supports both mainnet and devnet for development/testing.

```elixir
defmodule XPando.Blockchain.SolanaRPC do
  @mainnet_url "https://api.mainnet-beta.solana.com"
  @devnet_url "https://api.devnet.solana.com"
  
  def get_account_info(wallet_address, network \\ :mainnet) do
    url = if network == :mainnet, do: @mainnet_url, else: @devnet_url
    
    body = %{
      jsonrpc: "2.0",
      id: 1,
      method: "getAccountInfo",
      params: [wallet_address, %{encoding: "base64"}]
    }
    
    case http_client().post(url, body) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response["result"]}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

## Redis Cache API

- **Purpose:** High-performance caching for AI responses, node status, and knowledge query results
- **Documentation:** https://redis.io/commands/
- **Base URL(s):** Direct TCP connection (default port 6379)
- **Authentication:** AUTH command with password (if configured)
- **Rate Limits:** No explicit limits, bounded by memory and network capacity

**Key Endpoints Used:**
- `SET/GET` - Cache AI provider responses and knowledge queries
- `HSET/HGET` - Store node metadata and connection status
- `EXPIRE` - Set TTL for cached data to prevent stale information

**Integration Notes:** Primary caching layer for all high-frequency operations. Implements cache-aside pattern with automatic cache warming for critical data. Redis clustering configured for high availability.

## Fly.io Platform API

- **Purpose:** Infrastructure management, deployment automation, and global edge scaling
- **Documentation:** https://fly.io/docs/hands-on/flyctl/
- **Base URL(s):** https://api.fly.io/v1
- **Authentication:** Bearer token via Fly.io API token
- **Rate Limits:** 1,000 requests/hour for most endpoints

**Key Endpoints Used:**
- `GET /apps` - List deployed xPando instances across regions
- `POST /apps/{app}/deploy` - Trigger deployments for scaling operations
- `GET /apps/{app}/status` - Monitor application health and performance

**Integration Notes:** Used for automated scaling based on node network size and performance metrics. Integration primarily through flyctl CLI and GitHub Actions rather than direct API calls.
