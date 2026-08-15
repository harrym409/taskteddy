"""Geolocation utilities for distance calculations.

Uses Haversine formula for accurate distance calculation between coordinates.
"""
from __future__ import annotations

from math import asin, cos, radians, sin, sqrt

# Earth's radius in kilometers
EARTH_RADIUS_KM = 6371.0

# Default and maximum search radius
DEFAULT_RADIUS_KM = 40.0
MAX_RADIUS_KM = 50.0


def haversine_distance(
    lat1: float, lng1: float, lat2: float, lng2: float
) -> float:
    """Calculate the great-circle distance between two points on Earth.
    
    Uses the Haversine formula for accurate distance calculation.
    
    Args:
        lat1: Latitude of first point (degrees)
        lng1: Longitude of first point (degrees)
        lat2: Latitude of second point (degrees)
        lng2: Longitude of second point (degrees)
        
    Returns:
        Distance in kilometers
    """
    # Convert to radians
    lat1_rad = radians(lat1)
    lng1_rad = radians(lng1)
    lat2_rad = radians(lat2)
    lng2_rad = radians(lng2)
    
    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlng = lng2_rad - lng1_rad
    
    a = sin(dlat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlng / 2) ** 2
    c = 2 * asin(sqrt(a))
    
    return EARTH_RADIUS_KM * c


def is_within_radius(
    point_lat: float | None,
    point_lng: float | None,
    center_lat: float | None,
    center_lng: float | None,
    radius_km: float = DEFAULT_RADIUS_KM,
) -> bool:
    """Check if a point is within a given radius of a center point.
    
    Args:
        point_lat: Latitude of the point to check
        point_lng: Longitude of the point to check
        center_lat: Latitude of the center point
        center_lng: Longitude of the center point
        radius_km: Radius in kilometers (default: 20km)
        
    Returns:
        True if point is within radius, False otherwise
    """
    # Can't calculate without coordinates
    if None in (point_lat, point_lng, center_lat, center_lng):
        return False
    
    distance = haversine_distance(point_lat, point_lng, center_lat, center_lng)
    return distance <= radius_km


def filter_by_radius(
    items: list[dict],
    center_lat: float,
    center_lng: float,
    radius_km: float = DEFAULT_RADIUS_KM,
    lat_field: str = "latitude",
    lng_field: str = "longitude",
) -> list[dict]:
    """Filter a list of items by distance from a center point.
    
    Args:
        items: List of dictionaries with lat/lng fields
        center_lat: Latitude of the center point
        center_lng: Longitude of the center point
        radius_km: Radius in kilometers
        lat_field: Name of latitude field in items
        lng_field: Name of longitude field in items
        
    Returns:
        Filtered list of items within radius, sorted by distance (nearest first)
    """
    if not items:
        return []
    
    # Calculate distance for each item
    scored = []
    for item in items:
        item_lat = item.get(lat_field)
        item_lng = item.get(lng_field)
        
        if item_lat is not None and item_lng is not None:
            distance = haversine_distance(center_lat, center_lng, item_lat, item_lng)
            if distance <= radius_km:
                scored.append((distance, item))
    
    # Sort by distance (nearest first)
    scored.sort(key=lambda x: x[0])
    
    return [item for _, item in scored]


def get_distance_km(
    lat1: float, lng1: float, lat2: float, lng2: float
) -> float:
    """Get distance between two points in kilometers.
    
    Convenience function wrapping haversine_distance.
    """
    return haversine_distance(lat1, lng1, lat2, lng2)


def format_distance(distance_km: float) -> str:
    """Format distance for display.
    
    Args:
        distance_km: Distance in kilometers
        
    Returns:
        Formatted string like "5.2 km" or "< 1 km"
    """
    if distance_km < 1:
        return "< 1 km"
    elif distance_km < 10:
        return f"{distance_km:.1f} km"
    else:
        return f"{round(distance_km)} km"
