import requests


OSRM_URL = "https://router.project-osrm.org/route/v1/driving"


def calculate_road_distance(
    origin_lat: float,
    origin_lng: float,
    destination_lat: float,
    destination_lng: float
):

    url = (
        f"{OSRM_URL}/"
        f"{origin_lng},{origin_lat};"
        f"{destination_lng},{destination_lat}"
    )

    params = {
        "overview": "false"
    }

    response = requests.get(
        url,
        params=params,
        timeout=30
    )

    if response.status_code != 200:

        raise Exception(
            f"OSRM request failed: "
            f"{response.status_code}"
        )

    data = response.json()

    if data.get("code") != "Ok":

        raise Exception(
            f"OSRM routing failed: "
            f"{data.get('code')}"
        )

    routes = data.get("routes", [])

    if not routes:

        raise Exception(
            "No road route found."
        )

    route = routes[0]

    distance_meters = route.get(
        "distance",
        0
    )

    duration_seconds = route.get(
        "duration",
        0
    )

    return {

        "distanceMeters": round(
            distance_meters
        ),

        "distanceKm": round(
            distance_meters / 1000,
            2
        ),

        "durationMinutes": round(
            duration_seconds / 60,
            1
        )
    }