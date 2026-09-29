import re
import time
import requests

from firebase_service import db


# ==========================================================
# NOMINATIM
# ==========================================================

NOMINATIM_URL = (
    "https://nominatim.openstreetmap.org/search"
)

HEADERS = {
    "User-Agent": "AgriConnectAI/1.0"
}


# ==========================================================
# CREATE MARKET ID
# ==========================================================

def create_market_id(
    market_name: str,
    district: str,
    state: str,
):
    """
    Create a clean Firestore document ID.
    """

    value = (
        f"{state}_{district}_{market_name}"
    )

    value = value.lower()

    value = re.sub(
        r"[^a-z0-9]+",
        "_",
        value,
    )

    value = value.strip("_")

    return value


# ==========================================================
# GEOCODE MARKET
# ==========================================================

def geocode_market(
    market_name: str,
    district: str,
    state: str,
):
    """
    Get market coordinates using Nominatim.
    """

    queries = [
        f"{market_name}, {district}, {state}, India",
        f"{market_name}, {district}, Maharashtra, India",
        f"{district}, {state}, India",
    ]

    for query in queries:

        params = {
            "q": query,
            "format": "json",
            "limit": 1,
            "countrycodes": "in",
        }

        try:

            response = requests.get(
                NOMINATIM_URL,
                params=params,
                headers=HEADERS,
                timeout=20,
            )

            if response.status_code != 200:
                continue

            results = response.json()

            if results:

                result = results[0]

                return {
                    "latitude": float(
                        result["lat"]
                    ),
                    "longitude": float(
                        result["lon"]
                    ),
                    "locationName": result.get(
                        "display_name",
                        "",
                    ),
                }

        except Exception:
            continue

        # Respect Nominatim request rate.
        time.sleep(1)

    return None


# ==========================================================
# CREATE MARKET
# ==========================================================

def create_market(
    market_name: str,
    district: str,
    state: str,
):
    """
    Create a market in Firestore if it does not exist.
    """

    market_id = create_market_id(
        market_name=market_name,
        district=district,
        state=state,
    )

    market_ref = (
        db
        .collection("markets")
        .document(market_id)
    )

    existing = market_ref.get()

    # ------------------------------------------------------
    # MARKET ALREADY EXISTS
    # ------------------------------------------------------

    if existing.exists:

        return {
            "success": True,
            "created": False,
            "message": "Market already exists.",
            "market": existing.to_dict(),
        }

    # ------------------------------------------------------
    # GET COORDINATES
    # ------------------------------------------------------

    coordinates = geocode_market(
        market_name=market_name,
        district=district,
        state=state,
    )

    if coordinates is None:

        return {
            "success": False,
            "created": False,
            "message": "Coordinates not found.",
            "marketName": market_name,
            "district": district,
            "state": state,
        }

    # ------------------------------------------------------
    # MARKET DATA
    # ------------------------------------------------------

    market_data = {

        "marketId": market_id,

        "name": market_name,

        "district": district,

        "state": state,

        "latitude": coordinates["latitude"],

        "longitude": coordinates["longitude"],

        "locationName": coordinates[
            "locationName"
        ],

        # Automatically geocoded.
        # We keep this false until verified.
        "verified": False,

        "isActive": True,

        "createdAt": time.time(),

        "updatedAt": time.time(),
    }

    # ------------------------------------------------------
    # SAVE TO FIRESTORE
    # ------------------------------------------------------

    market_ref.set(market_data)

    return {
        "success": True,
        "created": True,
        "market": market_data,
    }


# ==========================================================
# GET MARKET BY ID
# ==========================================================

def get_market_by_id(
    market_id: str,
):
    """
    Get one market.
    """

    doc = (
        db
        .collection("markets")
        .document(market_id)
        .get()
    )

    if not doc.exists:
        return None

    return doc.to_dict()


# ==========================================================
# GET ACTIVE MARKETS
# ==========================================================

def get_active_markets(
    state: str = "Maharashtra",
):
    """
    Get active markets for a state.
    """

    docs = (
        db
        .collection("markets")
        .where(
            "state",
            "==",
            state,
        )
        .where(
            "isActive",
            "==",
            True,
        )
        .stream()
    )

    markets = []

    for doc in docs:

        data = doc.to_dict()

        data["id"] = doc.id

        markets.append(data)

    return markets