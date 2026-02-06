# Project Chimera - Functional Specification
**Version:** 1.0  
**Last Updated:** February 6, 2026  
**Status:** Draft

---

## 1. User Stories

### 1.1 Network Operator (Strategic Manager)

**As a** Network Operator  
**I want to** define high-level campaign goals  
**So that** agents can autonomously execute the strategy without micromanagement

**Acceptance Criteria:**
- Can create campaign via dashboard with natural language goal (e.g., "Promote summer fashion collection in Ethiopia")
- Can set budget constraints ($X per day, $Y total)
- Can define target audience (demographics, interests)
- Can pause/resume campaign at any time
- Can view real-time metrics (posts created, engagement rate, spend)

---

**As a** Network Operator  
**I want to** launch a new virtual influencer agent  
**So that** I can scale my influencer fleet without manual content creation

**Acceptance Criteria:**
- Can create agent in <2 hours from persona definition to first post
- Upload SOUL.md file with backstory, voice, values
- Configure social media accounts (Twitter, Instagram)
- Set up wallet for financial transactions
- Agent auto-generates first 10 posts for review

---

**As a** Network Operator  
**I want to** monitor fleet health via dashboard  
**So that** I can identify underperforming agents or system issues

**Acceptance Criteria:**
- Dashboard shows all agents' status (Active, Paused, Error)
- Real-time queue depth (tasks pending per agent)
- Current wallet balances (USDC, ETH)
- Cost per agent per day
- HITL queue size (tasks awaiting human review)
- Alerts for: budget exceeded, API failures, safety violations

---

### 1.2 Human Reviewer (HITL Moderator)

**As a** Human Reviewer  
**I want to** quickly approve or reject agent-generated content  
**So that** quality is maintained without becoming a bottleneck

**Acceptance Criteria:**
- Review queue shows tasks sorted by confidence score (lowest first)
- Each item shows: content preview, confidence score, reasoning trace
- Can approve/reject/edit with single click
- Can batch approve similar items
- Edits are fed back to improve confidence model

---

**As a** Human Reviewer  
**I want to** understand why content was escalated  
**So that** I can make informed decisions

**Acceptance Criteria:**
- System explains confidence score breakdown
- Shows which safety filters triggered
- Displays similar past content (approved/rejected)
- Allows marking false positives to reduce future escalations

---

### 1.3 Agent (Autonomous Influencer)

**As an** Agent  
**I want to** discover trending topics in my niche  
**So that** I can create timely, relevant content

**Acceptance Criteria:**
- Agent polls news MCP resource every 4 hours
- Semantic filter scores relevance to persona (>0.75 → creates task)
- Agent can search Twitter trends for hashtags
- Agent can query Google Trends API
- Trend data is stored in memory for future reference

---

**As an** Agent  
**I want to** generate multimodal content (text + image)  
**So that** I can post engaging social media content

**Acceptance Criteria:**
- Agent can generate Instagram caption matching persona voice
- Agent can create image using Ideogram with character consistency
- Judge validates image resembles persona (using vision model)
- Content must pass safety checks before posting
- If confidence <0.90, escalate to HITL queue

---

**As an** Agent  
**I want to** engage with my audience  
**So that** I can build authentic relationships

**Acceptance Criteria:**
- Agent monitors Twitter mentions every 10 minutes
- Agent can reply to comments/mentions within 10 seconds
- Replies maintain persona consistency
- Sensitive topics (politics, health advice) auto-escalate to HITL
- Trolling/abuse is ignored (no engagement)

---

**As an** Agent  
**I want to** manage my own finances  
**So that** I can pay for services without human intervention

**Acceptance Criteria:**
- Agent has non-custodial crypto wallet (Base network)
- Agent can check wallet balance before incurring costs
- Agent can send USDC to other agents (e.g., pay graphic designer)
- CFO Judge enforces daily spend limit
- All transactions logged on blockchain (immutable audit trail)

---

**As an** Agent  
**I want to** remember past interactions  
**So that** I can maintain conversation continuity

**Acceptance Criteria:**
- Short-term memory: Last 1 hour stored in Redis
- Long-term memory: Semantic search in Weaviate
- Agent recalls specific details from months-old conversations
- Memory is tenant-isolated (agent can't access other agents' memories)

---

### 1.4 Planner (Manager Agent)

**As a** Planner  
**I want to** decompose campaign goals into executable tasks  
**So that** workers can operate in parallel without coordination overhead

**Acceptance Criteria:**
- Reads campaign goal from GlobalState (PostgreSQL)
- Creates directed acyclic graph (DAG) of tasks
- Tasks are atomic (single tool call, <2 min execution)
- Dependencies are explicit (Task B depends on Task A completion)
- Re-plans dynamically if tasks fail or context changes

---

**As a** Planner  
**I want to** monitor external triggers  
**So that** I can react to real-time events

**Acceptance Criteria:**
- Polls MCP Resources every 5 minutes (news, trends, mentions)
- Creates tasks when trigger meets relevance threshold
- Prioritizes tasks (High, Medium, Low)
- Respects budget constraints before creating tasks

---

### 1.5 Worker (Executor Agent)

**As a** Worker  
**I want to** execute a single task with maximum focus  
**So that** I can complete it quickly and correctly

**Acceptance Criteria:**
- Pops single task from Redis queue
- Loads minimal context (persona + relevant memories)
- Uses MCP Tools for all external actions
- Returns result with confidence score
- Execution time <10 seconds for routine tasks

---

**As a** Worker  
**I want to** fail gracefully  
**So that** one error doesn't crash the entire system

**Acceptance Criteria:**
- Catches all exceptions and logs them
- Returns error details to Judge
- Does not retry (retry is Planner's responsibility)
- Terminates after task completion (ephemeral)

---

### 1.6 Judge (Governance Agent)

**As a** Judge  
**I want to** validate Worker output before committing  
**So that** only high-quality, safe content is published

**Acceptance Criteria:**
- Reviews every Worker result
- Checks confidence score against thresholds
- Validates persona consistency (brand voice match)
- Runs safety filters (profanity, hate speech, prompt injection)
- Implements Optimistic Concurrency Control (OCC) for state commits

---

**As a** Judge  
**I want to** escalate ambiguous content to humans  
**So that** safety is maintained without excessive automation risk

**Acceptance Criteria:**
- Routes to HITL queue if confidence <0.90
- Provides reasoning trace for human reviewer
- Continues with other tasks (doesn't block)
- Learns from human feedback to improve confidence model

---

## 2. Functional Requirements by Component

### 2.1 Cognitive Core (Persona & Memory)

**FR-CC-001:** The system SHALL load agent persona from SOUL.md file  
**Priority:** P0 (Critical)  
**Implementation:** Pydantic model parses YAML frontmatter + markdown body

**FR-CC-002:** The system SHALL retrieve relevant memories before each LLM call  
**Priority:** P0  
**Implementation:** Query Weaviate with semantic search, return top 5 results

**FR-CC-003:** The system SHALL update long-term memory after successful interactions  
**Priority:** P1  
**Implementation:** Judge triggers background task to summarize and store in Weaviate

---

### 2.2 Perception System (Data Ingestion)

**FR-PS-001:** The system SHALL poll MCP Resources at configurable intervals  
**Priority:** P0  
**Implementation:** Async cron job calls `mcp.get_resource(uri)` every N minutes

**FR-PS-002:** The system SHALL filter ingested content by semantic relevance  
**Priority:** P1  
**Implementation:** Lightweight LLM scores content 0.0-1.0, threshold configurable

**FR-PS-003:** The system SHALL detect trending topics  
**Priority:** P2  
**Implementation:** Background Worker clusters news/mentions, triggers alert if 5+ related items in 4 hours

---

### 2.3 Creative Engine (Content Generation)

**FR-CE-001:** The system SHALL generate text content matching persona voice  
**Priority:** P0  
**Implementation:** System prompt includes SOUL.md + recent memories, LLM generates

**FR-CE-002:** The system SHALL generate images with character consistency  
**Priority:** P0  
**Implementation:** Ideogram MCP with `character_reference_id` parameter

**FR-CE-003:** The system SHALL validate generated images  
**Priority:** P1  
**Implementation:** Vision model compares generated image to reference, reject if mismatch

---

### 2.4 Action System (Social Interface)

**FR-AS-001:** The system SHALL publish content via MCP Tools only  
**Priority:** P0  
**Implementation:** No direct API calls; all actions via `mcp.call_tool()`

**FR-AS-002:** The system SHALL reply to mentions within 10 seconds  
**Priority:** P1  
**Implementation:** Worker pool auto-scales based on mention queue depth

**FR-AS-003:** The system SHALL rate limit API calls  
**Priority:** P0  
**Implementation:** MCP server enforces platform rate limits (e.g., 300 tweets/3 hours)

---

### 2.5 Agentic Commerce (Financial Autonomy)

**FR-AC-001:** The system SHALL create wallet for each agent  
**Priority:** P1  
**Implementation:** Coinbase AgentKit `create_wallet()` on agent initialization

**FR-AC-002:** The system SHALL enforce budget limits  
**Priority:** P0  
**Implementation:** CFO Judge checks `daily_spend` in Redis before approving transactions

**FR-AC-003:** The system SHALL log all transactions on-chain  
**Priority:** P0  
**Implementation:** Every `send_payment()` writes to blockchain (Base network)

---

### 2.6 Orchestration (Swarm Management)

**FR-OR-001:** The system SHALL implement Planner-Worker-Judge pattern  
**Priority:** P0  
**Implementation:** Three separate services communicating via Redis queues

**FR-OR-002:** The system SHALL support Optimistic Concurrency Control  
**Priority:** P1  
**Implementation:** Judge checks `state_version` before commit, rollback if stale

**FR-OR-003:** The system SHALL auto-scale Worker pool  
**Priority:** P1  
**Implementation:** Kubernetes HPA scales 10-100 pods based on queue depth

---

### 2.7 Human-in-the-Loop (Safety Layer)

**FR-HL-001:** The system SHALL use confidence-based escalation  
**Priority:** P0  
**Implementation:** >0.90 auto-approve, 0.70-0.90 HITL, <0.70 reject

**FR-HL-002:** The system SHALL provide review interface  
**Priority:** P1  
**Implementation:** React dashboard consuming HITL queue from Redis

**FR-HL-003:** The system SHALL learn from human feedback  
**Priority:** P2  
**Implementation:** Approved/rejected items used to fine-tune confidence model

---

## 3. Non-Functional Requirements

### 3.1 Performance

**NFR-PF-001:** End-to-end latency for routine tasks SHALL be <10 seconds (p95)  
**NFR-PF-002:** System uptime SHALL be 99.9% (measured monthly)  
**NFR-PF-003:** Worker pool SHALL scale to 100 pods within 2 minutes

### 3.2 Security

**NFR-SC-001:** All agent execution SHALL occur in sandboxed containers  
**NFR-SC-002:** Prompt injection attempts SHALL be detected and logged  
**NFR-SC-003:** Wallet private keys SHALL be stored in AWS Secrets Manager

### 3.3 Cost

**NFR-CO-001:** Cost per social media post SHALL be <$0.50 (all-in)  
**NFR-CO-002:** Daily spend SHALL not exceed configured budget (hard limit)  
**NFR-CO-003:** Resource Governor SHALL block tasks if budget reached

### 3.4 Usability

**NFR-US-001:** Agent launch time SHALL be <2 hours (persona → first post)  
**NFR-US-002:** Dashboard SHALL support 1 operator managing 50+ agents  
**NFR-US-003:** HITL review SHALL take <30 seconds per item

---

## 4. Edge Cases & Error Handling

### 4.1 API Failures

**Scenario:** Twitter API returns 503 Service Unavailable  
**Expected Behavior:**
- Worker logs error and returns failure status
- Planner reschedules task with exponential backoff (1m, 2m, 4m, 8m)
- After 5 retries, escalate to human operator

### 4.2 Budget Exhaustion

**Scenario:** Agent daily budget limit reached  
**Expected Behavior:**
- CFO Judge rejects all new tasks
- Planner pauses campaign
- Dashboard shows "Budget Exhausted" alert
- Auto-resume next day at midnight UTC

### 4.3 Confidence Disagreement

**Scenario:** Worker confidence 0.95, Judge confidence 0.65  
**Expected Behavior:**
- Judge confidence takes precedence
- Content escalated to HITL queue
- Discrepancy logged for model improvement

### 4.4 State Drift (OCC Conflict)

**Scenario:** Judge attempts commit but state_version changed  
**Expected Behavior:**
- Judge invalidates Worker result
- Planner receives "stale state" signal
- Planner re-plans with updated state
- Worker re-executes task with new context

---

## 5. Acceptance Testing Scenarios

### 5.1 End-to-End Content Creation

**Given:** Campaign goal "Promote Ethiopian coffee culture"  
**When:** Planner receives goal  
**Then:**
1. Planner creates task DAG (research trends → generate caption → create image → post to Instagram)
2. Worker #1 researches trends, returns "Ethiopian coffee ceremony" topic
3. Worker #2 generates caption matching persona voice
4. Worker #3 creates image with character consistency
5. Judge validates (confidence 0.92 → auto-approve)
6. Worker #4 posts to Instagram
7. GlobalState updated with post ID and timestamp

**Success Criteria:** All steps complete in <60 seconds, no human intervention

---

### 5.2 HITL Escalation

**Given:** Worker generates political commentary (sensitive topic)  
**When:** Judge reviews content  
**Then:**
1. Safety filter detects political keywords
2. Confidence score 0.78 (medium)
3. Judge escalates to HITL queue
4. Human reviewer sees content + reasoning
5. Human rejects content
6. Feedback stored to improve future filtering

**Success Criteria:** Content does NOT publish, human sees reasoning within 30s

---

### 5.3 Budget Enforcement

**Given:** Agent has $10 daily budget, current spend $9.80  
**When:** Worker requests $0.50 image generation  
**Then:**
1. CFO Judge checks `daily_spend` in Redis ($9.80)
2. Calculates remaining budget ($0.20)
3. Rejects task (would exceed budget)
4. Returns error to Planner
5. Planner pauses campaign
6. Dashboard shows budget alert

**Success Criteria:** Transaction blocked, budget not exceeded

---

## 6. Future Enhancements (Post-MVP)

**FR-FE-001:** A/B testing framework for content variations  
**FR-FE-002:** Sentiment analysis on audience comments  
**FR-FE-003:** Multi-language support (Spanish, Amharic, Arabic)  
**FR-FE-004:** Voice generation for video content  
**FR-FE-005:** Integration with Shopify for e-commerce

---

**Document Status:** DRAFT - Awaiting Ratification  
**Next Review:** End of Phase 0 (Week 2)
