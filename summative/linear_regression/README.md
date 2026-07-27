# Linear Regression Task — Health Access in Sub-Saharan Africa

## Mission
This project supports the mission of improving health access for underserved
communities in Sub-Saharan Africa by using data to understand which factors
are most strongly associated with maternal mortality — a key indicator of
how well a country's health system reaches mothers, especially in rural and
low-resource settings.

## Dataset description and source
The dataset is a **country-year panel** built from the **World Bank Open Data
API** (https://api.worldbank.org), covering **48 Sub-Saharan African
countries** across the years **2000-2022**. Ten health, economic, and
infrastructure indicators were pulled directly from the World Bank's public
API for every available (country, year) combination — not just a single
snapshot per country — giving the dataset both volume (many observations
per country over time) and variety (health, economic, and infrastructure
indicators together).

**Target variable:** `maternal_mortality_ratio` — maternal deaths per
100,000 live births (World Bank indicator `SH.STA.MMRT`)

**Predictor variables:**
- `skilled_birth_attendance_pct` — % of births attended by skilled health staff
- `health_expenditure_per_capita` — current health expenditure per capita (US$)
- `gdp_per_capita` — GDP per capita (US$)
- `physicians_per_1000` — physicians per 1,000 people
- `hospital_beds_per_1000` — hospital beds per 1,000 people
- `female_literacy_rate_pct` — adult female literacy rate (ages 15+)
- `rural_population_pct` — % of population living in rural areas
- `access_to_electricity_pct` — % of population with access to electricity
- `antenatal_care_4visits_pct` — % of pregnant women with 4+ antenatal visits

Data was retrieved programmatically via `01_fetch_data_v2.py`, which calls
the World Bank API directly (no manual download) and saves the panel as
`ssa_maternal_health_panel.csv`.

## Visualizations and interpretation
*(see below / see the generated PNGs — correlation heatmap and distribution
plots are included and interpreted in the sections that follow)*
