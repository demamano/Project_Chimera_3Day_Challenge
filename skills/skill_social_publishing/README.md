# Skill: Social Publishing

## Purpose
Publish content to social media platforms (Twitter, Instagram, TikTok) via MCP servers.

## Input Schema

```python
class SocialPublishingInput(BaseModel):
    agent_id: str
    platform: Literal["twitter", "instagram", "tiktok", "threads"]
    content: Dict[str, Any]  # {'text': '...', 'media_urls': ['...']}
    scheduling: Optional[Dict] = None  # {'publish_at': '2026-02-06T18:00:00Z'}
    disclosure_level: Literal["automated", "assisted", "none"] = "automated"
```

## Output Schema

```python
class SocialPublishingOutput(BaseModel):
    success: bool
    post_id: str  # Platform-specific post ID
    post_url: str
    published_at: datetime
    confidence_score: float
    error: Optional[str] = None
```

## Example Usage

```python
from skills.skill_social_publishing import execute

input = SocialPublishingInput(
    agent_id="agent_123",
    platform="instagram",
    content={
        'text': 'Check out this Ethiopian coffee ceremony...',
        'media_urls': ['https://cdn.chimera.ai/img456.jpg']
    },
    disclosure_level="automated"
)

result = await execute(input, mcp_client)
# result.post_id = "CAbcd1234"
# result.post_url = "https://instagram.com/p/CAbcd1234"
```

## MCP Dependencies
- `twitter` - Twitter API wrapper
- `instagram` - Instagram Graph API wrapper  
- `tiktok` - TikTok API wrapper (future)

## Platform-Specific Requirements

### Twitter
- Max 280 characters (auto-truncate or thread)
- Max 4 images or 1 video
- Rate limit: 300 tweets per 3 hours

### Instagram
- Max 2,200 characters
- Requires image (1:1, 4:5, or 16:9)
- Supports carousels (max 10 images)

### TikTok
- Video required (15s - 10min)
- Max 2,200 characters
- Auto-add #TikTokMadeMeBuyIt if product mention

## Error Handling
- Rate limit exceeded → Queue for later retry
- Invalid media format → Convert or reject
- Duplicate content detected → Modify and retry
