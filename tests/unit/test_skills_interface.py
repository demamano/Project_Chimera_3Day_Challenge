"""
Test suite for Skills Interface.
These tests SHOULD FAIL initially (TDD approach).
"""

import pytest
from pydantic import ValidationError


def test_content_generation_skill_interface():
    """
    SPEC: skills/skill_content_generation/README.md
    
    Given: Content generation skill exists
    When: Called with valid input
    Then: Returns output matching schema
    """
    # This will fail because skill doesn't exist yet
    from skills.skill_content_generation import execute, ContentGenerationInput
    
    input_data = ContentGenerationInput(
        agent_id="test_agent_123",
        content_type="instagram_post",
        topic="Ethiopian coffee culture",
        platform="instagram",
        include_image=True
    )
    
    # Skill should be async
    import asyncio
    result = asyncio.run(execute(input_data, mcp_client=None))
    
    # Validate output structure
    assert hasattr(result, "success")
    assert hasattr(result, "content")
    assert hasattr(result, "confidence_score")
    assert hasattr(result, "reasoning")
    
    # Validate data types
    assert isinstance(result.success, bool)
    assert isinstance(result.confidence_score, float)
    assert 0.0 <= result.confidence_score <= 1.0


def test_social_publishing_skill_interface():
    """
    SPEC: skills/skill_social_publishing/README.md
    
    Given: Social publishing skill exists
    When: Called with valid input
    Then: Returns output matching schema
    """
    from skills.skill_social_publishing import execute, SocialPublishingInput
    
    input_data = SocialPublishingInput(
        agent_id="test_agent_123",
        platform="twitter",
        content={
            "text": "Test post from Chimera agent",
            "media_urls": []
        },
        disclosure_level="automated"
    )
    
    import asyncio
    result = asyncio.run(execute(input_data, mcp_client=None))
    
    assert hasattr(result, "success")
    assert hasattr(result, "post_id")
    assert hasattr(result, "post_url")
    assert hasattr(result, "published_at")


def test_trend_analysis_skill_interface():
    """
    SPEC: skills/skill_trend_analysis/README.md
    
    Given: Trend analysis skill exists
    When: Called with valid input
    Then: Returns output matching schema
    """
    from skills.skill_trend_analysis import execute, TrendAnalysisInput
    
    input_data = TrendAnalysisInput(
        agent_id="test_agent_123",
        niche=["fashion", "ethiopian culture"],
        sources=["news", "twitter"],
        time_window="24h",
        min_relevance_score=0.75
    )
    
    import asyncio
    result = asyncio.run(execute(input_data, mcp_client=None))
    
    assert hasattr(result, "success")
    assert hasattr(result, "trends")
    assert hasattr(result, "confidence_score")
    assert isinstance(result.trends, list)


def test_skill_input_validation():
    """
    Given: Invalid input to skill
    When: Skill is called
    Then: Should raise ValidationError
    """
    from skills.skill_content_generation import ContentGenerationInput
    
    # Missing required field 'agent_id'
    with pytest.raises(ValidationError):
        ContentGenerationInput(
            content_type="instagram_post",
            topic="Test",
            platform="instagram"
            # Missing agent_id (required)
        )


def test_skill_accepts_mcp_client():
    """
    SPEC: research/tooling_strategy.md - Section 4
    
    Given: Any skill
    When: Execute is called
    Then: It should accept mcp_client parameter
    """
    from skills.skill_content_generation import execute
    import inspect
    
    # Check function signature
    sig = inspect.signature(execute)
    params = list(sig.parameters.keys())
    
    assert "mcp_client" in params, \
        "Skill execute() must accept mcp_client parameter"


def test_skill_returns_confidence_score():
    """
    SPEC: specs/functional.md - NFR-HL-001
    
    Given: Any skill execution
    When: Complete
    Then: Must return confidence_score between 0.0 and 1.0
    """
    from skills.skill_content_generation import execute, ContentGenerationInput
    
    input_data = ContentGenerationInput(
        agent_id="test_agent_123",
        content_type="twitter_thread",
        topic="AI trends",
        platform="twitter",
        include_image=False
    )
    
    import asyncio
    result = asyncio.run(execute(input_data, mcp_client=None))
    
    assert hasattr(result, "confidence_score")
    assert isinstance(result.confidence_score, (int, float))
    assert 0.0 <= result.confidence_score <= 1.0


@pytest.mark.asyncio
async def test_skill_error_handling():
    """
    Given: Skill encounters error (e.g., API timeout)
    When: Execute is called
    Then: Should return success=False with error message
    """
    from skills.skill_social_publishing import execute, SocialPublishingInput
    from unittest.mock import AsyncMock
    
    # Mock MCP client that raises error
    mock_mcp = AsyncMock()
    mock_mcp.call_tool.side_effect = TimeoutError("API timeout")
    
    input_data = SocialPublishingInput(
        agent_id="test_agent_123",
        platform="twitter",
        content={"text": "Test"}
    )
    
    result = await execute(input_data, mcp_client=mock_mcp)
    
    # Use 'not result.success' instead of '== False'
    assert not result.success
    assert result.error is not None
    assert "timeout" in result.error.lower()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])