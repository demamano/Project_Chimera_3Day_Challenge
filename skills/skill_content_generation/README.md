# Skill: Content Generation

## Purpose
Generate multimodal social media content (text + images) matching agent persona and campaign goals.

## Input Schema

```python
class ContentGenerationInput(BaseModel):
    agent_id: str
    content_type: Literal["instagram_post", "twitter_thread", "tiktok_caption"]
    topic: str
    platform: Literal["instagram", "twitter", "tiktok"]
    target_audience: Optional[str] = None
    style_preferences: Optional[List[str]] = None
    include_image: bool = True
    character_reference_id: Optional[str] = None
```

## Output Schema

```python
class ContentGenerationOutput(BaseModel):
    success: bool
    content: Dict[str, Any]  # {'text': '...', 'image_url': '...'}
    confidence_score: float  # 0.0 to 1.0
    reasoning: str
    cost_usd: float
    error: Optional[str] = None
```

## Example Usage

```python
from skills.skill_content_generation import execute

input = ContentGenerationInput(
    agent_id="agent_123",
    content_type="instagram_post",
    topic="Ethiopian coffee culture",
    platform="instagram",
    include_image=True,
    character_reference_id="stellar_fashion_ref_001"
)

result = await execute(input, mcp_client)
# result.content = {
#     'text': 'Absolutely LIVED for the Ethiopian coffee ceremony...',
#     'image_url': 'https://cdn.chimera.ai/img456.jpg'
# }
```

## MCP Dependencies
- `weaviate` - Retrieve persona and past successful content
- `ideogram` - Generate image with character consistency
- `gemini` or `claude` - Generate caption text

## Error Handling
- Insufficient budget → raise `BudgetExceededError`
- Character inconsistency → retry with adjusted prompt
- API timeout → retry with exponential backoff (max 3 attempts)
