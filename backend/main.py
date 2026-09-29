from fastapi import FastAPI, HTTPException
from dotenv import load_dotenv
import os
import requests
import time

from firebase_service import db
from routes_service import calculate_road_distance
from market_service import (
    create_market,
    get_active_markets,
)

load_dotenv()

app = FastAPI(
    title="AgriConnect AI Backend",
    version="1.0.0"
)


# ============================================================
# ENVIRONMENT VARIABLES
# ============================================================

API_KEY = os.getenv("DATA_GOV_API_KEY")

API_URL = os.getenv(
    "DATA_GOV_API_URL",
    "https://api.data.gov.in/resource/"
    "9ef84268-d588-465a-a308-a864a43d0070"
)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def normalize_state(state: str) -> str:
    """
    Normalize farmer state values.

    For this Maharashtra project:
    Maharashtra / MH / Satara -> Maharashtra

    Long-term, farmer profiles should store:
        state = Maharashtra
        district = Satara
    """

    if not state:
        return "Maharashtra"

    state_clean = str(state).strip().lower()

    if state_clean in [
        "maharashtra",
        "mh",
        "maharastra",
        "maharashtra state",
        "satara"
    ]:
        return "Maharashtra"

    return str(state).strip()


def safe_float(value, default=0.0):
    """
    Safely convert a value to float.
    """

    try:
        if value is None or value == "":
            return default

        return float(value)

    except (ValueError, TypeError):
        return default


def government_api_request(params):
    """
    Common function for calling data.gov.in API.
    """

    if not API_KEY:
        raise HTTPException(
            status_code=500,
            detail="DATA_GOV_API_KEY is missing."
        )

    try:

        response = requests.get(
            API_URL,
            params=params,
            headers={
                "User-Agent": "AgriConnectAI/1.0"
            },
            timeout=(15, 120)
        )

        response.raise_for_status()

        return response.json()

    except requests.Timeout:

        raise HTTPException(
            status_code=504,
            detail="Government API request timed out."
        )

    except requests.RequestException as e:

        raise HTTPException(
            status_code=502,
            detail="Unable to connect to government market API."
        )

    except ValueError:

        raise HTTPException(
            status_code=502,
            detail="Government API returned invalid JSON."
        )


# ============================================================
# BASIC ROOT
# ============================================================

@app.get("/")
def root():

    return {
        "success": True,
        "message": "AgriConnect AI Backend is running.",
        "version": "1.0.0"
    }


# ============================================================
# TEST FIRESTORE
# ============================================================

@app.get("/test-firestore")
def test_firestore():

    test_ref = db.collection(
        "backend_test"
    ).document("test")

    test_ref.set({
        "message": "Backend connected to Firestore",
        "timestamp": time.time()
    })

    return {
        "success": True,
        "message": "Firestore connection successful."
    }


# ============================================================
# GOVERNMENT MARKET PRICE API
# ============================================================

@app.get("/market-prices")
def market_prices(
    commodity: str = "Tomato",
    state: str = "Maharashtra",
    limit: int = 100
):

    state = normalize_state(state)

    if limit <= 0:
        raise HTTPException(
            status_code=400,
            detail="Limit must be greater than zero."
        )

    params = {
        "api-key": API_KEY,
        "format": "json",
        "limit": limit,
        "filters[state.keyword]": state,
        "filters[commodity.keyword]": commodity,
    }

    data = government_api_request(params)

    records = data.get(
        "records",
        []
    )

    return {
        "success": True,
        "commodity": commodity,
        "state": state,
        "totalRecords": len(records),
        "records": records
    }


# ============================================================
# SYNC MARKET PRICES TO FIRESTORE
# ============================================================

@app.get("/sync-market-prices")
def sync_market_prices(
    commodity: str = "Tomato",
    state: str = "Maharashtra"
):

    state = normalize_state(state)

    all_records = []

    offset = 0
    limit = 500

    while True:

        params = {
            "api-key": API_KEY,
            "format": "json",
            "limit": limit,
            "offset": offset,
            "filters[state.keyword]": state,
            "filters[commodity.keyword]": commodity,
        }

        data = government_api_request(params)

        records = data.get(
            "records",
            []
        )

        if not records:
            break

        all_records.extend(
            records
        )

        if len(records) < limit:
            break

        offset += limit

    # --------------------------------------------------------
    # SAVE TO FIRESTORE
    # --------------------------------------------------------

    saved = 0

    batch = db.batch()
    batch_count = 0

    for index, record in enumerate(all_records):

        document_id = (
            f"{state}_"
            f"{commodity}_"
            f"{record.get('market', '')}_"
            f"{record.get('arrival_date', '')}_"
            f"{index}"
        )

        document_id = (
            document_id
            .lower()
            .replace(" ", "_")
            .replace("/", "_")
            .replace("\\", "_")
        )

        ref = db.collection(
            "market_prices"
        ).document(document_id)

        batch.set(
            ref,
            {
                "state": state,

                "district": record.get(
                    "district"
                ),

                "market": record.get(
                    "market"
                ),

                "commodity": record.get(
                    "commodity"
                ),

                "variety": record.get(
                    "variety"
                ),

                "grade": record.get(
                    "grade"
                ),

                "arrivalDate": record.get(
                    "arrival_date"
                ),

                "minPrice": safe_float(
                    record.get("min_price")
                ),

                "maxPrice": safe_float(
                    record.get("max_price")
                ),

                "modalPrice": safe_float(
                    record.get("modal_price")
                ),

                "updatedAt": time.time(),
            },
            merge=True
        )

        batch_count += 1
        saved += 1

        # Firestore batch limit is 500.
        # Keep below the limit.
        if batch_count >= 400:

            batch.commit()

            batch = db.batch()
            batch_count = 0

    if batch_count > 0:

        batch.commit()

    return {
        "success": True,
        "message": (
            "Market prices synchronized successfully."
        ),
        "commodity": commodity,
        "state": state,
        "totalRecords": len(all_records),
        "saved": saved
    }


# ============================================================
# BEST MARKET BASED ONLY ON MODAL PRICE
# ============================================================

@app.get("/best-market")
def best_market(
    commodity: str = "Tomato",
    state: str = "Maharashtra"
):

    state = normalize_state(state)

    params = {
        "api-key": API_KEY,
        "format": "json",
        "limit": 100,
        "filters[state.keyword]": state,
        "filters[commodity.keyword]": commodity,
    }

    data = government_api_request(
        params
    )

    records = data.get(
        "records",
        []
    )

    if not records:

        return {
            "success": False,
            "message": (
                "No market price records found."
            )
        }

    valid_records = []

    for record in records:

        modal_price = safe_float(
            record.get("modal_price")
        )

        if modal_price <= 0:
            continue

        valid_records.append({

            "market": record.get(
                "market"
            ),

            "district": record.get(
                "district"
            ),

            "commodity": record.get(
                "commodity"
            ),

            "modalPrice": modal_price,

            "minPrice": safe_float(
                record.get("min_price")
            ),

            "maxPrice": safe_float(
                record.get("max_price")
            ),

            "arrivalDate": record.get(
                "arrival_date"
            )
        })

    if not valid_records:

        return {
            "success": False,
            "message": (
                "No valid market prices found."
            )
        }

    valid_records.sort(
        key=lambda x: x["modalPrice"],
        reverse=True
    )

    return {

        "success": True,

        "commodity": commodity,

        "state": state,

        "bestMarket": valid_records[0],

        "markets": valid_records
    }


# ============================================================
# TEST OSRM
# ============================================================

@app.get("/test-road-distance")
def test_road_distance(
    origin_lat: float,
    origin_lng: float,
    destination_lat: float,
    destination_lng: float
):

    try:

        route = calculate_road_distance(
            origin_lat,
            origin_lng,
            destination_lat,
            destination_lng
        )

        return {

            "success": True,

            "route": route
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


# ============================================================
# CREATE MARKET
# ============================================================

@app.post("/markets/create")
def create_market_endpoint(
    market: str,
    district: str,
    state: str = "Maharashtra"
):

    state = normalize_state(
        state
    )

    result = create_market(
        market_name=market,
        district=district,
        state=state
    )

    if not result.get(
        "success"
    ):

        raise HTTPException(
            status_code=400,
            detail=result.get(
                "message"
            )
        )

    return result


# ============================================================
# GET ACTIVE MARKETS
# ============================================================

@app.get("/markets")
def markets_endpoint(
    state: str = "Maharashtra"
):

    state = normalize_state(
        state
    )

    markets = get_active_markets(
        state
    )

    return {

        "success": True,

        "state": state,

        "total": len(markets),

        "markets": markets
    }


# ============================================================
# SYNC MARKETS FROM GOVERNMENT DATA
# ============================================================

@app.get("/sync-markets")
def sync_markets(
    commodity: str = "Tomato",
    state: str = "Maharashtra"
):

    state = normalize_state(
        state
    )

    params = {

        "api-key": API_KEY,

        "format": "json",

        "limit": 100,

        "filters[state.keyword]": state,

        "filters[commodity.keyword]": commodity,
    }

    data = government_api_request(
        params
    )

    records = data.get(
        "records",
        []
    )

    unique_markets = {}

    for record in records:

        market_name = record.get(
            "market"
        )

        district = record.get(
            "district"
        )

        if not market_name or not district:
            continue

        market_name = market_name.strip()
        district = district.strip()

        key = (
            market_name.lower(),
            district.lower()
        )

        unique_markets[key] = {

            "market": market_name,

            "district": district
        }

    created = 0
    existing = 0
    failed = 0

    results = []

    for item in unique_markets.values():

        result = create_market(

            market_name=item["market"],

            district=item["district"],

            state=state
        )

        if result.get(
            "success"
        ):

            if result.get(
                "created"
            ):

                created += 1

            else:

                existing += 1

        else:

            failed += 1

        results.append({

            "market": item["market"],

            "district": item["district"],

            "result": result
        })

    return {

        "success": True,

        "message": (
            "Markets synchronized successfully."
        ),

        "state": state,

        "commodity": commodity,

        "totalRecords": len(records),

        "uniqueMarkets": len(
            unique_markets
        ),

        "created": created,

        "existing": existing,

        "failed": failed,

        "markets": results
    }


# ============================================================
# REAL MARKET RECOMMENDATION
# ============================================================

@app.get("/best-market-net-return")
def best_market_net_return(

    farmer_id: str,

    commodity: str = "Tomato",

    quantity: float = 100,

    unit: str = "Kg",

    transport_cost_per_km: float = 15.0
):

    # ========================================================
    # 1. VALIDATE INPUT
    # ========================================================

    if not farmer_id.strip():

        raise HTTPException(
            status_code=400,
            detail="Farmer ID is required."
        )

    if not commodity.strip():

        raise HTTPException(
            status_code=400,
            detail="Commodity is required."
        )

    if quantity <= 0:

        raise HTTPException(
            status_code=400,
            detail=(
                "Quantity must be greater than zero."
            )
        )

    if transport_cost_per_km < 0:

        raise HTTPException(
            status_code=400,
            detail=(
                "Transport cost cannot be negative."
            )
        )

    # ========================================================
    # 2. GET FARMER PROFILE
    # ========================================================

    farmer_ref = db.collection(
        "farmers"
    ).document(
        farmer_id
    )

    farmer_doc = farmer_ref.get()

    if not farmer_doc.exists:

        raise HTTPException(
            status_code=404,
            detail=(
                "Farmer profile not found."
            )
        )

    farmer = farmer_doc.to_dict()

    farmer_lat = farmer.get(
        "latitude"
    )

    farmer_lng = farmer.get(
        "longitude"
    )

    farmer_district = farmer.get(
        "district",
        ""
    )

    # IMPORTANT:
    # State and district are different.
    #
    # Example:
    # state = Maharashtra
    # district = Satara

    farmer_state = normalize_state(
        farmer.get(
            "state",
            "Maharashtra"
        )
    )

    # ========================================================
    # 3. VALIDATE GPS
    # ========================================================

    if farmer_lat is None or farmer_lng is None:

        raise HTTPException(
            status_code=400,
            detail=(
                "Farmer GPS location is missing. "
                "Please save your location in "
                "Farmer Profile."
            )
        )

    try:

        farmer_lat = float(
            farmer_lat
        )

        farmer_lng = float(
            farmer_lng
        )

    except (
        ValueError,
        TypeError
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Farmer GPS coordinates are invalid."
            )
        )

    # ========================================================
    # 4. CONVERT QUANTITY TO QUINTALS
    # ========================================================

    unit_clean = (
        unit.strip()
        .lower()
    )

    if unit_clean in [
        "kg",
        "kgs",
        "kilogram",
        "kilograms"
    ]:

        quantity_quintal = (
            quantity / 100
        )

    elif unit_clean in [
        "quintal",
        "quintals",
        "qtl"
    ]:

        quantity_quintal = quantity

    elif unit_clean in [
        "ton",
        "tons",
        "tonne",
        "tonnes"
    ]:

        quantity_quintal = (
            quantity * 10
        )

    else:

        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid unit. "
                "Use Kg, Quintal or Ton."
            )
        )

    # ========================================================
    # 5. GET GOVERNMENT MARKET PRICES
    # ========================================================

    params = {

        "api-key": API_KEY,

        "format": "json",

        "limit": 100,

        "filters[state.keyword]": farmer_state,

        "filters[commodity.keyword]": commodity,
    }

    data = government_api_request(
        params
    )

    records = data.get(
        "records",
        []
    )

    if not records:

        return {

            "success": False,

            "message": (
                "No market prices found "
                "for this commodity."
            ),

            "state": farmer_state,

            "commodity": commodity
        }

    # ========================================================
    # 6. GET FIRESTORE MARKET MASTER
    # ========================================================

    markets = get_active_markets(
        farmer_state
    )

    # ========================================================
    # 7. CREATE MARKET LOOKUP
    # ========================================================

    market_lookup = {}

    for market in markets:

        market_name = str(
            market.get(
                "name",
                ""
            )
        ).strip().lower()

        district = str(
            market.get(
                "district",
                ""
            )
        ).strip().lower()

        if not market_name or not district:
            continue

        key = (
            market_name,
            district
        )

        market_lookup[key] = market

    # ========================================================
    # 8. MATCH PRICE WITH MARKET
    # ========================================================

    candidates = []

    for record in records:

        market_name = str(
            record.get(
                "market",
                ""
            )
        ).strip()

        district = str(
            record.get(
                "district",
                ""
            )
        ).strip()

        if not market_name or not district:
            continue

        key = (

            market_name.lower(),

            district.lower()
        )

        market = market_lookup.get(
            key
        )

        if not market:
            continue

        market_lat = market.get(
            "latitude"
        )

        market_lng = market.get(
            "longitude"
        )

        if market_lat is None or market_lng is None:
            continue

        modal_price = safe_float(
            record.get(
                "modal_price"
            )
        )

        if modal_price <= 0:
            continue

        candidates.append({

            "market": market_name,

            "district": district,

            "marketId": market.get(
                "marketId"
            ),

            "latitude": market_lat,

            "longitude": market_lng,

            "modalPrice": modal_price,

            "minPrice": safe_float(
                record.get(
                    "min_price"
                )
            ),

            "maxPrice": safe_float(
                record.get(
                    "max_price"
                )
            ),

            "arrivalDate": record.get(
                "arrival_date"
            ),

            "verified": market.get(
                "verified",
                False
            )
        })

    # ========================================================
    # 9. CHECK CANDIDATES
    # ========================================================

    if not candidates:

        return {

            "success": False,

            "message": (
                "No markets with valid coordinates "
                "and prices were found."
            ),

            "commodity": commodity,

            "state": farmer_state
        }

    # ========================================================
    # 10. REMOVE DUPLICATE MARKETS
    # ========================================================

    unique_candidates = {}

    for candidate in candidates:

        key = (

            candidate["market"].lower(),

            candidate["district"].lower()
        )

        if key not in unique_candidates:

            unique_candidates[key] = candidate

        else:

            # Keep higher modal price
            if (
                candidate["modalPrice"]
                >
                unique_candidates[key]["modalPrice"]
            ):

                unique_candidates[key] = candidate

    candidates = list(
        unique_candidates.values()
    )

    # ========================================================
    # 11. CALCULATE DISTANCE + NET RETURN
    # ========================================================

    recommendations = []

    for candidate in candidates:

        try:

            route = calculate_road_distance(

                farmer_lat,

                farmer_lng,

                float(
                    candidate["latitude"]
                ),

                float(
                    candidate["longitude"]
                )
            )

            distance_km = float(
                route["distanceKm"]
            )

            duration_minutes = float(
                route["durationMinutes"]
            )

        except Exception as e:

            print(
                f"OSRM failed for "
                f"{candidate['market']}: {e}"
            )

            continue

        # ----------------------------------------------------
        # Gross selling value
        # ----------------------------------------------------

        gross_value = (

            quantity_quintal

            *
            candidate["modalPrice"]
        )

        # ----------------------------------------------------
        # Transport cost
        # ----------------------------------------------------

        transport_cost = (

            distance_km

            *
            transport_cost_per_km
        )

        # ----------------------------------------------------
        # Net return
        # ----------------------------------------------------

        net_return = (

            gross_value

            -
            transport_cost
        )

        recommendations.append({

            "market": candidate[
                "market"
            ],

            "district": candidate[
                "district"
            ],

            "marketId": candidate[
                "marketId"
            ],

            "modalPrice": round(
                candidate[
                    "modalPrice"
                ],
                2
            ),

            "minPrice": round(
                candidate[
                    "minPrice"
                ],
                2
            ),

            "maxPrice": round(
                candidate[
                    "maxPrice"
                ],
                2
            ),

            "quantity": quantity,

            "unit": unit,

            "quantityQuintal": round(
                quantity_quintal,
                2
            ),

            "distanceKm": round(
                distance_km,
                2
            ),

            "durationMinutes": round(
                duration_minutes,
                1
            ),

            "transportCostPerKm": round(
                transport_cost_per_km,
                2
            ),

            "transportCost": round(
                transport_cost,
                2
            ),

            "grossValue": round(
                gross_value,
                2
            ),

            "netReturn": round(
                net_return,
                2
            ),

            "arrivalDate": candidate[
                "arrivalDate"
            ],

            "coordinateStatus": (

                "verified"

                if candidate[
                    "verified"
                ]

                else "approximate"
            )
        })

        # Small delay between OSRM calls
        time.sleep(
            0.2
        )

    # ========================================================
    # 12. CHECK ROUTES
    # ========================================================

    if not recommendations:

        return {

            "success": False,

            "message": (
                "Unable to calculate road routes "
                "for available markets."
            ),

            "commodity": commodity,

            "state": farmer_state
        }

    # ========================================================
    # 13. SORT BY NET RETURN
    # ========================================================

    recommendations.sort(

        key=lambda x: x[
            "netReturn"
        ],

        reverse=True
    )

    # ========================================================
    # 14. BEST MARKET
    # ========================================================

    best = recommendations[0]

    # ========================================================
    # 15. FINAL RESPONSE
    # ========================================================

    return {

        "success": True,

        "message": (
            "Market recommendation calculated "
            "using government market prices, "
            "road distance and net return."
        ),

        "farmerId": farmer_id,

        "farmerLocation": {

            "latitude": farmer_lat,

            "longitude": farmer_lng,

            "district": farmer_district,

            "state": farmer_state
        },

        "commodity": commodity,

        "quantity": quantity,

        "unit": unit,

        "quantityQuintal": round(
            quantity_quintal,
            2
        ),

        "transportCostPerKm": round(
            transport_cost_per_km,
            2
        ),

        "bestMarket": best,

        "totalMarketsEvaluated": len(
            recommendations
        ),

        "rankedMarkets": recommendations
    }