from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
from .regime_detector import check_regime

app = FastAPI(title="MAKTAB API")

class OverrideData(BaseModel):
    sbp_rate: float = None
    pkr_usd: float = None
    forex_reserves: float = None
    fipi: float = None

class RegimeDeclaration(BaseModel):
    trigger_description: str

@app.get("/predict/crypto")
async def predict_crypto(force: bool = False):
    # Check regime first
    regime = check_regime()
    if regime["active"] and not force:
        return {
            "market": "crypto",
            "direction": "neutral",
            "confidence": 0,
            "factors": [],
            "rangeLow": 0,
            "rangeHigh": 0,
            "regimeActive": True,
            "message": "Prediction suspended due to active regime: " + regime["trigger"]
        }
    
    # Placeholder for actual model inference
    # In reality, we'd load crypto_model.pkl and run prediction
    return {
        "market": "crypto",
        "direction": "up",
        "confidence": 85,
        "factors": [
            {"name": "btc_price", "currentValue": 65000, "unit": "$", "weightPercentage": 40, "direction": "up", "change24h": 5.2, "isManual": False, "tooltip": "BTC Price", "isSplitFactor": False}
        ],
        "rangeLow": 64000,
        "rangeHigh": 68000,
        "regimeActive": regime["active"]
    }

@app.get("/predict/psx")
async def predict_psx(force: bool = False):
    regime = check_regime()
    if regime["active"] and not force:
        return {
            "market": "psx",
            "direction": "neutral",
            "confidence": 0,
            "factors": [],
            "rangeLow": 0,
            "rangeHigh": 0,
            "regimeActive": True
        }
    
    return {
        "market": "psx",
        "direction": "down",
        "confidence": 60,
        "factors": [
            {"name": "sbp_rate", "currentValue": 22.0, "unit": "%", "weightPercentage": 30, "direction": "down", "change24h": 0, "isManual": True, "tooltip": "SBP Rate", "isSplitFactor": False}
        ],
        "rangeLow": 60000,
        "rangeHigh": 61000,
        "regimeActive": regime["active"]
    }

@app.post("/override")
async def update_overrides(data: OverrideData):
    # Write to local file that the Python fetchers will read
    with open("data/manual_overrides.json", "w") as f:
        json.dump(data.dict(), f)
    return {"status": "success"}

@app.get("/health")
async def get_health():
    # Placeholder for actual health checks
    return [
        {"sourceName": "CoinGecko", "status": "ok", "latencyMs": 120},
        {"sourceName": "FRED", "status": "ok", "latencyMs": 300},
        {"sourceName": "YFinance", "status": "stale", "latencyMs": 50}
    ]

@app.post("/regime/declare")
async def declare_regime(data: RegimeDeclaration):
    # Manually declare regime
    return {"status": "success", "trigger": data.trigger_description}
