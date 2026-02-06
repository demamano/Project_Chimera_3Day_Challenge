# Skill: Trend Analysis

## Purpose
Discover and analyze trending topics relevant to agent's niche by monitoring news, social media, and search trends.

## Input Schema

```python
class TrendAnalysisInput(BaseModel):
    agent_id: str
    niche: List[str]  # e.g., ["fashion", "ethiopian culture", "streetwear"]
    sources: List[Literal["news", "twitter", "google_trends"]] = ["news", "twitter"]
    time_window: Literal["1h", "6h", "24h", "7d"] = "24h"
    min_relevance_score: float = 0.75
    max_results: int = 10
```

## Output Schema

```python
class TrendAnalysisOutput(BaseModel):
    success: bool
    trends: List[Trend]
    confidence_score: float
    analyzed_at: datetime
    error: Optional[str] = None

class Trend(BaseModel):
    topic: str
    relevance_score: float  # 0.0 to 1.0
    sources: List[str]  # URLs or references
    sentiment: Literal["positive", "neutral", "negative"]
    velocity: Literal["rising", "stable", "declining"]
    recommended_action: str  # e.g., "Create content ASAP", "Monitor", "Skip"
```

## Example Usage

```python
from skills.skill_trend_analysis import execute

input = TrendAnalysisInput(
    agent_id="agent_123",
    niche=["ethiopian fashion", "african streetwear"],
    sources=["news", "twitter"],
    time_window="24h",
    min_relevance_score=0.75
)

result = await execute(input, mcp_client)
# result.trends = [
#     {
#         'topic': 'Ethiopian Fashion Week 2026',
#         'relevance_score': 0.92,
#         'sources': ['https://vogue.com/...', 'twitter://...'],
#         'sentiment': 'positive',
#         'velocity': 'rising',
#         'recommended_action': 'Create content ASAP'
#     }
# ]
```

## MCP Dependencies
- `news` - RSS feeds, NewsAPI, Bing News
- `twitter` - Twitter Trends API
- `google_trends` - Google Trends API (pytrends)
- `weaviate` - Semantic similarity search against past content

## Analysis Pipeline

1. **Fetch Data** from configured sources
2. **Semantic Filtering** using LLM to score relevance
3. **Clustering** to group related topics
4. **Velocity Detection** comparing to historical data
5. **Sentiment Analysis** positive/negative/neutral
6. **Recommendation** based on relevance + velocity

## Error Handling
- API rate limit → Fall back to cached trends
- No trends found → Return empty list with success=True
- Timeout → Retry with reduced time_window
