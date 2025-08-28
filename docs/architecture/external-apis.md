# External APIs

## OpenAI API

- **Purpose:** Primary AI provider for GPT model inference
- **Documentation:** https://platform.openai.com/docs
- **Base URL(s):** https://api.openai.com/v1
- **Authentication:** Bearer token (API key)
- **Rate Limits:** Tier-based, typically 10,000 TPM for standard accounts

**Key Endpoints Used:**
- `POST /chat/completions` - Generate AI responses
- `POST /embeddings` - Create vector embeddings for knowledge

**Integration Notes:** Implement exponential backoff for rate limit handling, use streaming for long responses

## Anthropic API

- **Purpose:** Alternative AI provider for Claude model inference
- **Documentation:** https://docs.anthropic.com/claude/reference
- **Base URL(s):** https://api.anthropic.com
- **Authentication:** X-API-Key header
- **Rate Limits:** Account-based, negotiable for enterprise

**Key Endpoints Used:**
- `POST /messages` - Generate Claude responses
- `POST /complete` - Legacy completion endpoint

**Integration Notes:** Supports larger context windows, implement provider failover strategy

## Google AI (Gemini) API

- **Purpose:** Third AI provider for Gemini model inference
- **Documentation:** https://ai.google.dev/api/rest
- **Base URL(s):** https://generativelanguage.googleapis.com
- **Authentication:** API key or OAuth 2.0
- **Rate Limits:** 60 requests per minute default

**Key Endpoints Used:**
- `POST /v1/models/{model}:generateContent` - Generate Gemini responses
- `POST /v1/models/{model}:embedContent` - Create embeddings

**Integration Notes:** Supports multimodal inputs, consider for specialized tasks

## Solana RPC API

- **Purpose:** Blockchain interaction for XPD token operations
- **Documentation:** https://docs.solana.com/api/http
- **Base URL(s):** Multiple RPC endpoints for redundancy
- **Authentication:** None (public RPC) or API key for premium
- **Rate Limits:** Varies by provider, typically 100 requests/second

**Key Endpoints Used:**
- `POST /` with method `getBalance` - Check XPD token balances
- `POST /` with method `sendTransaction` - Submit token transfers
- `POST /` with method `getTransaction` - Monitor transaction status

**Integration Notes:** Use multiple RPC endpoints for reliability, implement transaction retry logic