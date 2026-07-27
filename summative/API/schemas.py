"""
schemas.py — request/response models with enforced types and range constraints.

Ranges below are set from the actual observed range of each indicator in the
World Bank Sub-Saharan Africa dataset used in Task 1, widened slightly to
allow for realistic values outside the exact training sample (e.g. a country
not in the original 48, or a future year).
"""

from pydantic import BaseModel, Field, ConfigDict


class MaternalHealthInput(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "year": 2022,
                "skilled_birth_attendance_pct": 55.0,
                "health_expenditure_per_capita": 40.0,
                "physicians_per_1000": 0.15,
                "female_literacy_rate_pct": 50.0,
                "access_to_electricity_pct": 35.0,
                "antenatal_care_4visits_pct": 45.0,
            }
        }
    )
    year: int = Field(
        ..., ge=2000, le=2035,
        description="Year of the observation/prediction (panel data spans 2000-2022; allows a few years beyond for near-future estimates)"
    )
    skilled_birth_attendance_pct: float = Field(
        ..., ge=0, le=100,
        description="Percentage of births attended by skilled health staff (0-100%)"
    )
    health_expenditure_per_capita: float = Field(
        ..., ge=0, le=2000,
        description="Current health expenditure per capita in current US$ (realistic upper bound for the region)"
    )
    physicians_per_1000: float = Field(
        ..., ge=0, le=10,
        description="Physicians per 1,000 people (observed range in SSA data: 0.02-6.7)"
    )
    female_literacy_rate_pct: float = Field(
        ..., ge=0, le=100,
        description="Adult female literacy rate, ages 15+ (0-100%)"
    )
    access_to_electricity_pct: float = Field(
        ..., ge=0, le=100,
        description="Percentage of population with access to electricity (0-100%)"
    )
    antenatal_care_4visits_pct: float = Field(
        ..., ge=0, le=100,
        description="Percentage of pregnant women with 4+ antenatal care visits (0-100%)"
    )


class PredictionResponse(BaseModel):
    model_used: str
    input_features: MaternalHealthInput
    predicted_maternal_mortality_ratio: float


class RetrainResponse(BaseModel):
    message: str
    rows_used_for_training: int
    train_mse: float
    test_mse: float
    test_r2: float
