# Project Chimera - Technical Specification
**Version:** 1.0  
**Last Updated:** February 6, 2026  
**Status:** Draft

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   ORCHESTRATOR                           │
│           (Dashboard + API Gateway)                      │
└──────────────────┬──────────────────────────────────────┘
                   │
           ┌───────┴───────┐
           │   PLANNER     │ (Manager Agent - Gemini 3 Pro)
           │   Service     │
           └───────┬───────┘
                   │ pushes tasks
           ┌───────▼───────┐
           │  TASK QUEUE   │ (Redis)
           └───────┬───────┘
                   │ pop tasks
         ┌─────────┴────────┬──────────┐
         ↓                  ↓          ↓
    ┌────────┐         ┌────────┐  ┌────────┐
    │WORKER 1│         │WORKER 2│  │WORKER N│ (Gemini Flash/Haiku)
    └────┬───┘         └────┬───┘  └────┬───┘
         │                  │            │
         └──────────────────┴────────────┘
                        │ push results
                ┌───────▼───────┐
                │ REVIEW QUEUE  │ (Redis)
                └───────┬───────┘
                        │
                ┌───────▼───────┐
                │     JUDGE     │ (Claude Opus/Gemini Pro)
                │    Service    │
                └───────┬───────┘
                        │
             ┌──────────┴──────────┐
             ↓                     ↓
      ┌──────────────┐      ┌──────────────┐
      │ GLOBAL STATE │      │  HITL QUEUE  │
      │ (PostgreSQL) │      │   (Redis)    │
      └──────────────┘      └──────────────┘
                   │
           ┌───────┴───────┬───────────┬──────────┐
           ↓               ↓           ↓          ↓
      ┌────────┐     ┌────────┐  ┌────────┐ ┌────────┐
      │Weaviate│     │  S3    │  │Blockchain│ │  MCP   │
      │(Memory)│     │(Media) │  │ (Ledger) │ │Servers │
      └────────┘     └────────┘  └──────────┘ └────────┘
```

---

## 2. Data Models & Schemas

### 2.1 PostgreSQL Schema

#### Table: `agents`
```sql
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    persona_file_path TEXT NOT NULL, -- Path to SOUL.md
    wallet_address VARCHAR(64),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'paused', 'error', 'deleted')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_agents_tenant ON agents(tenant_id);
CREATE INDEX idx_agents_status ON agents(status);
```

#### Table: `campaigns`
```sql
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    goals JSONB NOT NULL, -- Natural language goals + parsed tasks
    budget_daily_usd DECIMAL(10, 2),
    budget_total_usd DECIMAL(10, 2),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_campaigns_agent ON campaigns(agent_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
```

#### Table: `tasks`
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    task_type VARCHAR(50) NOT NULL, -- 'content_generation', 'reply_comment', 'execute_transaction'
    priority VARCHAR(10) NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'review', 'complete', 'failed')),
    context JSONB NOT NULL, -- Goal, persona constraints, required resources
    result JSONB, -- Worker output
    confidence_score DECIMAL(3, 2), -- 0.00 to 1.00
    assigned_worker_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    retries INT DEFAULT 0,
    error_message TEXT
);

CREATE INDEX idx_tasks_campaign ON tasks(campaign_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created ON tasks(created_at DESC);
```

#### Table: `hitl_reviews`
```sql
CREATE TABLE hitl_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id),
    content JSONB NOT NULL, -- The content awaiting review
    confidence_score DECIMAL(3, 2) NOT NULL,
    reasoning_trace TEXT, -- Why escalated
    reviewer_id UUID REFERENCES users(id),
    decision VARCHAR(20) CHECK (decision IN ('approved', 'rejected', 'edited')),
    edited_content JSONB,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_hitl_pending ON hitl_reviews(created_at) WHERE decision IS NULL;
```

#### Table: `transactions`
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id),
    transaction_hash VARCHAR(128) UNIQUE NOT NULL, -- Blockchain tx hash
    from_address VARCHAR(64) NOT NULL,
    to_address VARCHAR(64) NOT NULL,
    amount_usdc DECIMAL(20, 6) NOT NULL,
    network VARCHAR(20) NOT NULL, -- 'base', 'ethereum', 'solana'
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'confirmed', 'failed')),
    purpose TEXT, -- e.g., 'paid graphic designer', 'received sponsorship'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_transactions_agent ON transactions(agent_id);
CREATE INDEX idx_transactions_hash ON transactions(transaction_hash);
```

---

### 2.2 Weaviate Schema (Vector Database)

#### Class: `AgentMemory`
```python
{
    "class": "AgentMemory",
    "description": "Semantic memory for agent interactions and learnings",
    "multi_tenancy_config": {"enabled": True},
    "properties": [
        {
            "name": "agentId",
            "dataType": ["text"],
            "description": "UUID of the agent",
            "indexFilterable": True
        },
        {
            "name": "memoryType",
            "dataType": ["text"],
            "description": "conversation, learning, persona_update",
            "indexFilterable": True
        },
        {
            "name": "content",
            "dataType": ["text"],
            "description": "The actual memory content"
        },
        {
            "name": "context",
            "dataType": ["object"],
            "description": "Metadata like timestamp, platform, engagement"
        },
        {
            "name": "importance",
            "dataType": ["number"],
            "description": "Relevance score 0.0 to 1.0"
        },
        {
            "name": "timestamp",
            "dataType": ["date"],
            "description": "When memory was created"
        }
    ],
    "vectorizer": "text2vec-openai"
}
```

---

### 2.3 Redis Data Structures

#### Task Queue
```python
# Key: chimera:tasks:{priority}
# Type: List (FIFO)
# Value: JSON-serialized Task object
{
    "task_id": "uuid",
    "agent_id": "uuid",
    "task_type": "content_generation",
    "priority": "high",
    "context": {...},
    "created_at": "2026-02-06T10:30:00Z"
}
```

#### Review Queue
```python
# Key: chimera:review:{agent_id}
# Type: List (FIFO)
# Value: JSON-serialized Result object
{
    "task_id": "uuid",
    "result": {...},
    "confidence_score": 0.85,
    "reasoning": "Medium confidence due to novel topic"
}
```

#### Daily Spend Tracker
```python
# Key: chimera:spend:{agent_id}:{date}
# Type: String (float)
# TTL: 86400 seconds (24 hours)
# Value: "23.45" (current spend in USD)
```

#### Short-Term Memory
```python
# Key: chimera:memory:short:{agent_id}
# Type: List (circular buffer, max 100 items)
# TTL: 3600 seconds (1 hour)
# Value: JSON conversation history
```

---

## 3. API Specifications

### 3.1 Orchestrator REST API

**Base URL:** `https://api.chimera.aiqem.tech/v1`

#### POST `/agents`
Create a new agent

**Request:**
```json
{
    "name": "FashionNova AI",
    "persona_file": "base64_encoded_soul_md",
    "social_accounts": {
        "twitter": {"username": "fashionnova_ai"},
        "instagram": {"username": "fashionnova.ai"}
    },
    "budget": {
        "daily_usd": 50.00,
        "total_usd": 5000.00
    }
}
```

**Response:**
```json
{
    "agent_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "FashionNova AI",
    "status": "active",
    "wallet_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "created_at": "2026-02-06T10:30:00Z"
}
```

---

#### POST `/campaigns`
Create a campaign for an agent

**Request:**
```json
{
    "agent_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Summer Collection 2026",
    "goals": "Promote Ethiopian fashion designers and summer collection",
    "budget_daily_usd": 30.00,
    "duration_days": 14
}
```

**Response:**
```json
{
    "campaign_id": "660e8400-e29b-41d4-a716-446655440001",
    "status": "active",
    "estimated_posts": 42,
    "started_at": "2026-02-06T10:30:00Z"
}
```

---

#### GET `/agents/{agent_id}/metrics`
Get agent performance metrics

**Response:**
```json
{
    "agent_id": "550e8400-e29b-41d4-a716-446655440000",
    "period": "last_7_days",
    "metrics": {
        "posts_created": 28,
        "engagement_rate": 0.12,
        "followers_gained": 127,
        "spend_usd": 156.80,
        "revenue_usd": 234.50,
        "roi": 1.49,
        "autonomy_rate": 0.89
    }
}
```

---

#### GET `/hitl/queue`
Get pending HITL reviews

**Response:**
```json
{
    "total": 5,
    "items": [
        {
            "review_id": "770e8400-e29b-41d4-a716-446655440002",
            "agent_name": "FashionNova AI",
            "task_type": "content_generation",
            "content": {
                "text": "Check out this amazing Habesha Kemis design...",
                "image_url": "https://cdn.chimera.ai/img123.jpg"
            },
            "confidence_score": 0.78,
            "reasoning": "Mentions designer not in approved brand list",
            "created_at": "2026-02-06T10:25:00Z"
        }
    ]
}
```

---

### 3.2 MCP Tool Definitions

#### Tool: `post_content`
Post content to social media platform

**Definition:**
```json
{
    "name": "post_content",
    "description": "Publishes text and media to a connected social platform",
    "inputSchema": {
        "type": "object",
        "properties": {
            "platform": {
                "type": "string",
                "enum": ["twitter", "instagram", "threads"],
                "description": "Target platform"
            },
            "text_content": {
                "type": "string",
                "description": "The body of the post/tweet"
            },
            "media_urls": {
                "type": "array",
                "items": {"type": "string"},
                "description": "URLs to images/videos"
            },
            "disclosure_level": {
                "type": "string",
                "enum": ["automated", "assisted", "none"],
                "description": "AI disclosure level"
            }
        },
        "required": ["platform", "text_content"]
    }
}
```

---

#### Tool: `generate_image`
Generate image using AI model

**Definition:**
```json
{
    "name": "generate_image",
    "description": "Generates an image using Ideogram with character consistency",
    "inputSchema": {
        "type": "object",
        "properties": {
            "prompt": {
                "type": "string",
                "description": "Image generation prompt"
            },
            "character_reference_id": {
                "type": "string",
                "description": "ID for character consistency LoRA"
            },
            "style": {
                "type": "string",
                "enum": ["realistic", "anime", "artistic"],
                "default": "realistic"
            },
            "aspect_ratio": {
                "type": "string",
                "enum": ["1:1", "4:5", "16:9"],
                "default": "4:5"
            }
        },
        "required": ["prompt", "character_reference_id"]
    }
}
```

---

#### Tool: `send_payment`
Send cryptocurrency payment

**Definition:**
```json
{
    "name": "send_payment",
    "description": "Sends USDC payment to another wallet (agent or external)",
    "inputSchema": {
        "type": "object",
        "properties": {
            "to_address": {
                "type": "string",
                "pattern": "^0x[a-fA-F0-9]{40}$",
                "description": "Recipient wallet address"
            },
            "amount_usdc": {
                "type": "number",
                "minimum": 0.01,
                "description": "Amount in USDC"
            },
            "purpose": {
                "type": "string",
                "description": "Reason for payment"
            },
            "network": {
                "type": "string",
                "enum": ["base", "ethereum"],
                "default": "base"
            }
        },
        "required": ["to_address", "amount_usdc", "purpose"]
    }
}
```

---

#### Resource: `twitter://mentions/recent`
Fetch recent Twitter mentions

**Definition:**
```json
{
    "uri": "twitter://mentions/recent",
    "name": "Recent Twitter Mentions",
    "mimeType": "application/json",
    "description": "Returns mentions from last 1 hour"
}
```

**Response Format:**
```json
{
    "mentions": [
        {
            "id": "1234567890",
            "text": "@fashionnova_ai Love your style!",
            "author": "user123",
            "created_at": "2026-02-06T10:15:00Z",
            "engagement": {
                "likes": 5,
                "retweets": 1
            }
        }
    ],
    "fetched_at": "2026-02-06T10:30:00Z"
}
```

---

## 4. Communication Protocols

### 4.1 Planner → Worker
**Protocol:** Redis Queue (LPUSH/RPOP)  
**Message Format:**
```json
{
    "task_id": "uuid",
    "task_type": "content_generation",
    "priority": "high",
    "context": {
        "goal_description": "Create Instagram post about Ethiopian coffee",
        "persona_constraints": ["Friendly tone", "Use emoji sparingly"],
        "required_resources": ["mcp://weaviate/memory", "mcp://news/coffee"]
    },
    "assigned_worker_id": "worker-pod-42",
    "created_at": "2026-02-06T10:30:00Z",
    "deadline": "2026-02-06T10:35:00Z"
}
```

---

### 4.2 Worker → Judge
**Protocol:** Redis Queue (LPUSH/RPOP)  
**Message Format:**
```json
{
    "task_id": "uuid",
    "result": {
        "content_type": "instagram_post",
        "text": "Absolutely LIVED for the colors...",
        "media_url": "https://cdn.chimera.ai/img456.jpg"
    },
    "confidence_score": 0.92,
    "reasoning_trace": "High persona match (0.95), Safety approved (0.98), Novel topic (-0.05)",
    "tool_calls": [
        {"tool": "generate_image", "duration_ms": 1200},
        {"tool": "weaviate_search", "duration_ms": 45}
    ],
    "completed_at": "2026-02-06T10:31:23Z"
}
```

---

### 4.3 Judge → GlobalState
**Protocol:** PostgreSQL Transaction  
**Flow:**
1. Judge reads `state_version` from `campaigns` table
2. Validates Worker result
3. Begins transaction:
   - Check `state_version` unchanged (OCC)
   - Update `tasks` table (status = 'complete')
   - Insert to `hitl_reviews` if needed
   - Increment `state_version`
   - Commit
4. If version conflict → rollback, signal Planner to re-plan

---

## 5. System Configuration

### 5.1 Environment Variables

```bash
# AI Models
ANTHROPIC_API_KEY=sk-ant-xxxxx
GOOGLE_API_KEY=AIzaSyxxxxx
OPENAI_API_KEY=sk-xxxxx (fallback)

# Databases
POSTGRES_URL=postgresql://user:pass@localhost:5432/chimera
REDIS_URL=redis://localhost:6379/0
WEAVIATE_URL=http://localhost:8080

# Blockchain
CDP_API_KEY_NAME=organizations/xxx/apiKeys/xxx
CDP_API_KEY_PRIVATE_KEY=-----BEGIN EC PRIVATE KEY-----...
BLOCKCHAIN_NETWORK=base

# Budget & Limits
DEFAULT_DAILY_BUDGET_USD=100.00
MAX_TOKENS_PER_REQUEST=4096
WORKER_POOL_MIN=10
WORKER_POOL_MAX=100

# HITL
HITL_CONFIDENCE_THRESHOLD=0.90
HITL_AUTO_APPROVE=true

# Monitoring
PROMETHEUS_PORT=9090
SENTRY_DSN=https://xxx@sentry.io/xxx
```

---

### 5.2 Scaling Parameters

```yaml
# Kubernetes HorizontalPodAutoscaler
worker_pool:
  min_replicas: 10
  max_replicas: 100
  metrics:
    - type: External
      external:
        metric_name: redis_queue_depth
        target_value: 50  # tasks per pod

planner_service:
  replicas: 3  # Fixed, not auto-scaled

judge_service:
  min_replicas: 5
  max_replicas: 20
  metrics:
    - type: CPU
      target_utilization: 70
```

---

## 6. Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `E1001` | Budget exceeded | Pause campaign, notify operator |
| `E1002` | MCP server unavailable | Retry with backoff, escalate after 5 attempts |
| `E1003` | Prompt injection detected | Reject task, log incident |
| `E1004` | State version conflict (OCC) | Invalidate result, re-plan |
| `E1005` | Wallet insufficient funds | Pause financial tasks, notify operator |
| `E1006` | Content safety violation | Escalate to HITL, log for review |
| `E2001` | Worker timeout (>60s) | Kill worker, retry task |
| `E2002` | Database connection lost | Retry with circuit breaker |

---

## 7. Performance Targets

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Task ingestion rate | 1000 tasks/sec | Prometheus counter |
| P50 latency (routine) | <5 seconds | Histogram |
| P95 latency (routine) | <10 seconds | Histogram |
| P99 latency (complex) | <30 seconds | Histogram |
| Database query time | <50ms (p95) | APM tracing |
| Redis operation time | <5ms (p99) | APM tracing |
| Memory per worker | <512MB | Kubernetes metrics |

---

**Document Status:** DRAFT - Awaiting Ratification  
**Next Review:** End of Phase 0 (Week 2)
