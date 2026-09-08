import pandas as pd

customer_master = pd.read_csv("Raw/customer_master.csv")
customer_pricing = pd.read_csv("Raw/customer_pricing.csv")
material_master = pd.read_csv("Raw/material_master.csv")
spa_customers = pd.read_csv("Raw/spa_customers.csv")
spa_lines = pd.read_csv("Raw/spa_lines.csv")

customer_master = customer_master.dropna(how="all")
print("customer_master after cleaning:", len(customer_master))

analysis_base = spa_lines.merge(
    spa_customers,
    on="Agreement_ID",
    how="inner"
)

print("analysis_base rows after first merge:", len(analysis_base))

analysis_base = analysis_base.merge(
    customer_master,
    on="Customer_ID",
    how="inner"
)

print("after customer_master merge:", len(analysis_base))

analysis_base = analysis_base.merge(
    material_master,
    on="Material_ID",
    how="inner"
)

print("after material_master merge:", len(analysis_base))

analysis_base = analysis_base.merge(
    customer_pricing,
    on=["Customer_ID", "Material_ID"],
    how="left"
)

print("after customer_pricing merge:", len(analysis_base))

print(analysis_base.columns.tolist())

analysis_base = analysis_base.rename(columns={
    "Price_Unit_x": "SPA_Price_Unit",
    "Currency_x": "SPA_Currency",
    "Price_Unit_y": "Stock_Price_Unit",
    "Currency_y": "Stock_Currency",
    "Price_Unit": "Customer_Price_Unit",
    "Currency": "Customer_Price_Currency"
})

print(analysis_base.columns.tolist())

analysis_base["SPA_Unit_Price"] = (
    analysis_base["SPA_Price"] / analysis_base["SPA_Price_Unit"]
)

print(analysis_base[["SPA_Price", "SPA_Price_Unit", "SPA_Unit_Price"]])

def calculate_into_stock(row):
    if row["Pricing_Level"] == "ITEM":
        return row["Item_Price"] / row["Customer_Price_Unit"]
    elif row["Pricing_Level"] == "MG2":
        return (row["Stock_Price"] / row["Stock_Price_Unit"]) * row["MG2_Multiplier"]
    elif row["Pricing_Level"] == "MPG":
        return (row["Stock_Price"] / row["Stock_Price_Unit"]) * row["MPG_Multiplier"]
    elif row["Pricing_Level"] == "BOOK":
        return row["Book_Price"] / row["Customer_Price_Unit"]
    else:
        return row["Stock_Price"] / row["Stock_Price_Unit"]

analysis_base["Into_Stock_Price"] = analysis_base.apply(
calculate_into_stock,
axis=1
)

print(
analysis_base[
["Pricing_Level", "SPA_Unit_Price", "Into_Stock_Price"]
]
)

analysis_base["Price_Difference"] = (
    analysis_base["Into_Stock_Price"] - analysis_base["SPA_Unit_Price"]
)

analysis_base["SPA_Margin_Percent"] = (
    (analysis_base["SPA_Unit_Price"] - analysis_base["Unit_Cost"])
    / analysis_base["SPA_Unit_Price"]
) * 100

analysis_base["SPA_Benefit"] = analysis_base["Price_Difference"].apply(
    lambda x: "SPA BENEFIT" if x > 0 else "NO SPA BENEFIT"
)

analysis_base["Margin_Flag"] = analysis_base["SPA_Margin_Percent"].apply(
    lambda x: "NEGATIVE MARGIN" if x < 0 else "OK"
)

analysis_base["Benefit_Flag"] = analysis_base["SPA_Benefit"].apply(
    lambda x: 1 if x == "SPA BENEFIT" else 0
)

analysis_base["End_Date"] = pd.to_datetime(analysis_base["End_Date"])

today = pd.Timestamp.today().normalize()

analysis_base["Days_To_Expiry"] = (
    analysis_base["End_Date"] - today
).dt.days

def calculate_expiry_status(days):
    if days < 0:
        return "EXPIRED"
    elif days <= 30:
        return "EXPIRING <=30 DAYS"
    elif days <= 90:
        return "EXPIRING <=90 DAYS"
    else:
        return "ACTIVE"

analysis_base["Expiry_Status"] = analysis_base["Days_To_Expiry"].apply(
    calculate_expiry_status
)   

analysis_base["Expiry_Flag"] = analysis_base["Expiry_Status"].apply(
    lambda x: 1 if x == "EXPIRED" else 0
)

analysis_base["Review_Flag"] = (
    (analysis_base["Margin_Flag"] == "NEGATIVE MARGIN")
    | (analysis_base["Expiry_Flag"] == 1)
).astype(int)

print(
    analysis_base[
        [
            "Agreement_ID",
            "SPA_Benefit",
            "Margin_Flag",
            "Benefit_Flag",
            "Days_To_Expiry",
            "Expiry_Status",
            "Expiry_Flag",
            "Review_Flag"
        ]
    ]
)

agreement_summary = (
    analysis_base
    .groupby("Agreement_ID")
    .agg(
        Evaluation_Count=("Agreement_ID", "count"),
        Benefit_Count=("Benefit_Flag", "sum"),
        Review_Count=("Review_Flag", "sum")
    )
    .reset_index()
)

def calculate_agreement_action(row):
    if row["Benefit_Count"] == 0:
        return "DELETE SPA"
    elif row["Benefit_Count"] == row["Evaluation_Count"]:
        return "KEEP AS IS"
    else:
        return "SPLIT / UPDATE SPA"

agreement_summary["Agreement_Action"] = agreement_summary.apply(
    calculate_agreement_action,
    axis=1
)

print(agreement_summary)

analysis_base.to_csv(
    "Data/python_analysis_base.csv",
    index=False
)

agreement_summary.to_csv(
    "Data/python_agreement_summary.csv",
    index=False
)