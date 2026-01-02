import json
#from reportlab.lib import colors
#from reportlab.lib.pagesizes import letter
#from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Spacer, Paragraph
#from reportlab.lib.styles import getSampleStyleSheet

# Load Cyclone DX SBOM data from a JSON file (replace with your data loading mechanism)
with open('SBOM.json', 'r') as json_file:
    sbom_data = json.load(json_file)

# # Create a PDF document
# pdf_filename = 'sbom_report.pdf'
# doc = SimpleDocTemplate(pdf_filename, pagesize=letter)

# # Define styles for paragraphs
# styles = getSampleStyleSheet()
# normal_style = styles['Normal']
# heading_style = styles['Heading1']

# # Create content for the PDF
# elements = []

# # Add a title to the PDF
# elements.append(Paragraph('Cyclone DX SBOM Report', heading_style))
# elements.append(Spacer(1, 12))

# Process SBOM data and create a table
table_data = [['Component', 'Version', 'License']]
for component in sbom_data['components']:
    component_name = component['name']
    component_bom_ref = component['bom-ref']
    component_type = component['type']
    try: 
        component['licenses']):
        licenses = ', '.join(component['licenses'])
    except(Exception ):
        print()
    print("Component Name: {component_name}")
    print("Component Version: {component_}")
    print("Licenses: {licenses}")
    table_data.append([component_name, component_version, licenses])

# Create a table
# table = Table(table_data, colWidths=[200, 100, 200])
# table.setStyle(TableStyle([
#     ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
#     ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
#     ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
#     ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
#     ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
#     ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
#     ('GRID', (0, 0), (-1, -1), 1, colors.black),
# ]))

# Add the table to the elements list
# elements.append(table)

# Build the PDF document
# doc.build(elements)

#print(f"PDF report generated: {pdf_filename}")
