"""Fixed demo data: the 5 fake banks, their branches and ATMs.

All names, IFSC codes and numbers here are made up for the demo.
"""
from sqlalchemy.orm import Session

from .models import Atm, Bank, Branch

# City -> (state, lat, lng). Also used by the apps for "demo location".
CITIES: dict[str, tuple[str, float, float]] = {
    "Bengaluru": ("Karnataka", 12.9716, 77.5946),
    "Mysuru": ("Karnataka", 12.2958, 76.6394),
    "Mangaluru": ("Karnataka", 12.9141, 74.8560),
    "Mumbai": ("Maharashtra", 19.0760, 72.8777),
    "Pune": ("Maharashtra", 18.5204, 73.8567),
    "Nagpur": ("Maharashtra", 21.1458, 79.0882),
    "Delhi": ("Delhi", 28.6139, 77.2090),
    "Kolkata": ("West Bengal", 22.5726, 88.3639),
    "Chennai": ("Tamil Nadu", 13.0827, 80.2707),
    "Hyderabad": ("Telangana", 17.3850, 78.4867),
    "Visakhapatnam": ("Andhra Pradesh", 17.6868, 83.2185),
    "Kochi": ("Kerala", 9.9312, 76.2673),
    "Ahmedabad": ("Gujarat", 23.0225, 72.5714),
    "Jaipur": ("Rajasthan", 26.9124, 75.7873),
    "Bharatpur": ("Rajasthan", 27.2152, 77.4930),
    "Nuh": ("Haryana", 28.1024, 77.0016),
    "Lucknow": ("Uttar Pradesh", 26.8467, 80.9462),
    "Bhopal": ("Madhya Pradesh", 23.2599, 77.4126),
    "Patna": ("Bihar", 25.5941, 85.1376),
    "Ranchi": ("Jharkhand", 23.3441, 85.3096),
    "Jamtara": ("Jharkhand", 23.9628, 86.8023),
    "Deoghar": ("Jharkhand", 24.4826, 86.6950),
    "Guwahati": ("Assam", 26.1445, 91.7362),
}

BANKS = [
    # code, name, ifsc prefix, account prefix, card BIN, colour, tagline
    ("SAHY", "Sahyadri Bank", "SAHY", "3021", "608101", "#1B8A5A", "Strong like the Western Ghats"),
    ("GANG", "Ganga Bank", "GNGA", "4102", "608202", "#1E5BB8", "Flowing with trust"),
    ("KAVR", "Kaveri Bank", "KVRI", "5203", "608303", "#6B3FA0", "Nurturing every rupee"),
    ("NARM", "Narmada Bank", "NRMD", "6304", "608404", "#D9731A", "Banking at the heart of India"),
    ("GODA", "Godavari Bank", "GDVR", "7405", "608505", "#C62F3B", "Deep roots, wide reach"),
]

# bank code -> list of (branch name, city)
BRANCHES = {
    "SAHY": [("MG Road", "Bengaluru"), ("Whitefield", "Bengaluru"), ("Mysuru Main", "Mysuru"),
             ("Shivaji Nagar", "Pune"), ("Andheri East", "Mumbai"), ("Hampankatta", "Mangaluru")],
    "GANG": [("Connaught Place", "Delhi"), ("Hazratganj", "Lucknow"), ("Fraser Road", "Patna"),
             ("Park Street", "Kolkata"), ("Jamtara Bazar", "Jamtara"), ("Nuh Town", "Nuh")],
    "KAVR": [("T Nagar", "Chennai"), ("Jayanagar", "Bengaluru"), ("MG Road", "Kochi"),
             ("Banjara Hills", "Hyderabad"), ("Tower Chowk", "Deoghar"), ("Main Road", "Ranchi")],
    "NARM": [("CG Road", "Ahmedabad"), ("MP Nagar", "Bhopal"), ("Sitabuldi", "Nagpur"),
             ("MI Road", "Jaipur"), ("Kumher Gate", "Bharatpur"), ("Dadar", "Mumbai")],
    "GODA": [("Ameerpet", "Hyderabad"), ("Dwaraka Nagar", "Visakhapatnam"), ("Lalpur", "Ranchi"),
             ("Pan Bazaar", "Guwahati"), ("Salt Lake", "Kolkata"), ("Karol Bagh", "Delhi")],
}

# bank code -> list of (ATM name, city, small lat/lng offset so ATMs aren't on the branch)
ATMS = {
    "SAHY": [("Brigade Road", "Bengaluru", 0.004, 0.006), ("Koramangala", "Bengaluru", -0.035, 0.03),
             ("FC Road", "Pune", 0.01, -0.01), ("Jamtara Station", "Jamtara", 0.003, 0.004)],
    "GANG": [("Chandni Chowk", "Delhi", 0.04, 0.02), ("Jamtara Market", "Jamtara", -0.004, 0.002),
             ("Gandhi Maidan", "Patna", 0.006, 0.003), ("Nuh Bus Stand", "Nuh", 0.002, -0.003)],
    "KAVR": [("Anna Salai", "Chennai", 0.01, 0.02), ("Deoghar Temple Road", "Deoghar", 0.004, 0.003),
             ("HSR Layout", "Bengaluru", -0.06, 0.05), ("Hitech City", "Hyderabad", 0.06, -0.12)],
    "NARM": [("Johari Bazar", "Jaipur", 0.01, 0.03), ("Bharatpur Chowk", "Bharatpur", -0.003, 0.004),
             ("Navrangpura", "Ahmedabad", 0.012, -0.01), ("Bandra West", "Mumbai", -0.02, -0.04)],
    "GODA": [("Secunderabad", "Hyderabad", 0.05, 0.02), ("Howrah", "Kolkata", 0.01, -0.03),
             ("Doranda", "Ranchi", -0.02, -0.01), ("Deoghar Bus Stand", "Deoghar", -0.005, -0.004)],
}


def seed(db: Session) -> None:
    """Insert banks, branches and ATMs if the database is empty."""
    if db.query(Bank).count():
        return

    for code, name, ifsc_prefix, acc_prefix, card_bin, color, tagline in BANKS:
        db.add(Bank(code=code, name=name, ifsc_prefix=ifsc_prefix, account_prefix=acc_prefix,
                    card_bin=card_bin, color=color, tagline=tagline))

        for i, (branch_name, city) in enumerate(BRANCHES[code], start=1):
            state, lat, lng = CITIES[city]
            db.add(Branch(bank_code=code, name=f"{branch_name}, {city}", city=city, state=state,
                          ifsc=f"{ifsc_prefix}0{i:06d}", lat=lat, lng=lng))

        for i, (atm_name, city, dlat, dlng) in enumerate(ATMS[code], start=1):
            state, lat, lng = CITIES[city]
            db.add(Atm(id=f"{code}-ATM-{i:02d}", bank_code=code, name=f"{name} ATM - {atm_name}",
                       address=f"{atm_name}, {city}", city=city, state=state,
                       lat=round(lat + dlat, 6), lng=round(lng + dlng, 6)))
    db.commit()
