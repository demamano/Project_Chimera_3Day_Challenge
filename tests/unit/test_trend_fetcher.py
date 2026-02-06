"""
Test suite for Trend Fetcher functionality.
These tests SHOULD FAIL initially (TDD approach).
"""

import pytest


def test_trend_fetcher_returns_valid_structure():
    """
    SPEC: specs/technical.md - Section 4.2
    
    Given: A trend analysis request for "ethiopian fashion"
    When: The trend fetcher executes
    Then: It should return a list of trends with required fields
    """
    # This will fail because trend_fetcher module doesn't exist yet
    from services.planner.trend_fetcher import fetch_trends
    
    result = fetch_trends(
        niche=["ethiopian fashion"],
        time_window="24h",
        min_relevance_score=0.75
    )
    
    # Assert structure matches API contract
    assert isinstance(result, list)
    assert len(result) > 0
    
    trend = result[0]
    assert "topic" in trend
    assert "relevance_score" in trend
    assert "sources" in trend
    assert "sentiment" in trend
    assert "velocity" in trend
    
    # Assert data types
    assert isinstance(trend["topic"], str)
    assert 0.0 <= trend["relevance_score"] <= 1.0
    assert trend["sentiment"] in ["positive", "neutral", "negative"]
    assert trend["velocity"] in ["rising", "stable", "declining"]


def test_trend_fetcher_filters_by_relevance():
    """
    SPEC: specs/functional.md - FR-PS-002
    
    Given: min_relevance_score = 0.80
    When: Trends are fetched
    Then: All returned trends should have relevance_score >= 0.80
    """
    from services.planner.trend_fetcher import fetch_trends
    
    result = fetch_trends(
        niche=["fashion"],
        time_window="24h",
        min_relevance_score=0.80
    )
    
    for trend in result:
        assert trend["relevance_score"] >= 0.80, \
            f"Trend '{trend['topic']}' has score {trend['relevance_score']} < 0.80"


def test_trend_fetcher_handles_no_results():
    """
    SPEC: specs/technical.md - Error Handling
    
    Given: A very niche topic with no trends
    When: The trend fetcher executes
    Then: It should return empty list, not error
    """
    from services.planner.trend_fetcher import fetch_trends
    
    result = fetch_trends(
        niche=["very_obscure_nonexistent_topic_12345"],
        time_window="1h",
        min_relevance_score=0.95
    )
    
    assert isinstance(result, list)
    assert len(result) == 0  # Empty list is valid


def test_trend_fetcher_enforces_max_results():
    """
    Given: max_results = 5
    When: Trends are fetched
    Then: Should return at most 5 results
    """
    from services.planner.trend_fetcher import fetch_trends
    
    result = fetch_trends(
        niche=["technology"],
        time_window="7d",
        min_relevance_score=0.50,
        max_results=5
    )
    
    assert len(result) <= 5


@pytest.mark.asyncio
async def test_trend_fetcher_uses_mcp_resources():
    """
    SPEC: specs/technical.md - Section 4.1
    
    Given: Trend fetcher needs news data
    When: Executing
    Then: It should use MCP resource "news://latest"
    """
    from services.planner.trend_fetcher import fetch_trends_async
    from unittest.mock import AsyncMock
    
    # Mock MCP client
    mock_mcp = AsyncMock()
    mock_mcp.get_resource.return_value = {
        "articles": [
            {"title": "Ethiopian Fashion Week 2026", "url": "https://example.com"}
        ]
    }
    
    await fetch_trends_async(
        niche=["fashion"],
        time_window="24h",
        mcp_client=mock_mcp
    )
    
    # Verify MCP resource was called
    mock_mcp.get_resource.assert_called_once()
    call_args = mock_mcp.get_resource.call_args
    assert "news://" in str(call_args) or "twitter://" in str(call_args)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])