
import pandas as pd
from pathlib import Path

# List of CSV files (update if needed)
csv_files = list(Path(".").glob("*.csv"))

# Excel output
excel_writer = pd.ExcelWriter("aws_inventory_report.xlsx", engine="xlsxwriter")
summary_data = []

# Process each CSV
for csv_file in csv_files:
    try:
        df = pd.read_csv(csv_file)
        sheet_name = csv_file.stem[:31]  # Excel max sheet name length = 31
        df.to_excel(excel_writer, sheet_name=sheet_name, index=False)
        summary_data.append((sheet_name, len(df)))
    except Exception as e:
        print(f"Error processing {csv_file}: {e}")

# Summary sheet
summary_df = pd.DataFrame(summary_data, columns=["Service", "Resource Count"])
summary_df.to_excel(excel_writer, sheet_name="Summary", index=False)

excel_writer.close()

# Generate simple HTML report
with open("aws_inventory_report.html", "w") as html_out:
    html_out.write("<html><head><title>AWS Inventory Report</title></head><body>")
    html_out.write("<h1>AWS Inventory Summary</h1>")
    html_out.write(summary_df.to_html(index=False))
    for csv_file in csv_files:
        try:
            df = pd.read_csv(csv_file)
            html_out.write(f"<h2>{csv_file.stem}</h2>")
            html_out.write(df.head(100).to_html(index=False))  # Preview top 100 rows
        except Exception as e:
            html_out.write(f"<p>Error loading {csv_file.name}: {e}</p>")
    html_out.write("</body></html>")
