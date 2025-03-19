# ApexPdf
Native Apex re-implementation of jsPDF API using the Salesforce Apex language.
This implementation is an incomplete port of jsPDF to Apex.

inspiration: https://github.com/parallax/jsPDF

API docs that guide this project: https://raw.githack.com/MrRio/jsPDF/master/docs/index.html

# Compatibility
Initial assessment of what is supported and what is missing:

## Current Apex PDF API Functionality vs. jsPDF

### Current Features

1. **Text Operations**
   - Basic text addition with font size control
   - Text wrapping with configurable max width
   - Headings (h1, h2, h3)
   - Font styles (normal, bold, italic, bold-italic, strikethrough)
   - Combined styles (bold-strikethrough, italic-strikethrough, bold-italic-strikethrough)
   - Text color control (applies to both text and strikethrough line)
   - Vertical text positioning with auto-incrementing Y position
   - Text transformations (rotation, scaling)
   - Text opacity control
   - Watermark text on all pages

2. **Image Support**
   - JPEG image embedding
   - Image positioning and resizing

3. **Page Management**
   - Multi-page support
   - Page breaks
   - Coordinate tracking (lastX, lastY)

4. **Drawing Operations**
   - Rectangle drawing
   - Line drawing
   - Fill and stroke styles
   - Color control

5. **Table Support**
   - AutoTable implementation (similar to jsPDF-AutoTable)
   - Column configuration
   - Row styling
   - Header/body styling
   - Grid and striped themes

### Missing Features Compared to jsPDF

1. **Advanced Text Features**
   - Text alignment (center, right-align, justify)
   - Text decoration (underline, strikethrough)
   - Text spacing (character, word, line spacing)
   - Advanced text styling (gradient text, outlined text)

2. **Drawing Primitives**
   - Circles and ellipses (jsPDF has ellipse(), circle())
   - Bezier curves (bezierCurveTo(), quadraticCurveTo())
   - Polygon drawing (polygon())
   - Path operations (beginPath(), closePath())
   - Dashed/dotted line styles

3. **Advanced Image Support**
   - PNG support with transparency
   - SVG support
   - Image scaling modes (fit, stretch, contain)
   - Image rotation
   - Image masking/clipping

4. **Document Features**
   - Encryption and security (PDF password protection)
   - Document metadata (author, title, keywords)
   - Document outline/bookmarks
   - Hyperlinks (internal page links and external URLs)
   - Annotations (notes, highlights)

5. **Content Organization**
   - Templates/reusable components
   - Headers and footers (automatic on each page)
   - Page numbering (auto-generated)
   - Table of contents generation

6. **Advanced Layout**
   - Multi-column text layout (newspaper-style)
   - Text flowing around images
   - Floating elements
   - Layers/z-order control

7. **Form Elements**
   - Input fields (text fields, checkboxes, radio buttons)
   - Dropdown menus
   - Buttons

## Implementation Plan

Based on comparing our PDF API with jsPDF, here's a prioritized implementation plan:

### Phase 1: Essential Text Enhancements
1. **Text Alignment and Formatting**
   - Add alignment options (left, center, right, justify)
   - Enhance TextOptions class to include alignment property
   - Update text processing to handle alignment
   - Add strikethrough text styling
   - Support combining strikethrough with other styles (bold, italic)

2. **Document Metadata**
   - Add methods to set title, author, subject, keywords
   - Implement in PDF trailer/info dictionary

3. **Page Numbering**
   - Add auto page numbering functionality
   - Create footer/header template system

### Phase 2: Enhanced Drawing and Images
1. **Circle and Ellipse Drawing**
   - Add circle() and ellipse() methods
   - Implement using PDF drawing operators

2. **Line Styles**
   - Support for dashed/dotted lines
   - Line cap and join styles

3. **Enhanced Image Support**
   - Add PNG support with transparency
   - Improve image placement options

### Phase 3: Advanced Document Features
1. **Hyperlinks**
   - Internal page links
   - External URL links
   - Implement PDF annotation objects

2. **Document Outline/Bookmarks**
   - Create document outline structure
   - Auto-generate from headings

3. **Templates/Reusable Components**
   - Header and footer templates
   - Page templates
   - Reusable content blocks

### Phase 4: Layout and Organization
1. **Multi-column Layout**
   - Implement column-based text flow
   - Balance columns

2. **Text Decoration**
   - Underline
   - Additional text transformations

3. **Advanced Table Features**
   - Table spanning cells
   - Table header on each page
   - Table styling improvements

This implementation plan focuses on the most valuable features first while building toward a more complete PDF generation solution that matches jsPDF capabilities.

# Usage
This repo is intended to be included in a larger project as a git submodule.

After deploying the Apex PDF files to your org, the following example should produce a PDF file in the **Files** tab of your org.

```
// Basic PDF with headings and strikethrough text
Pdf doc = new Pdf();
doc.h1('Document with Strikethrough Examples', 72, 72);

// Normal text
doc.setFont('Helvetica', PdfConstants.STYLE_NORMAL);
doc.text('Normal text for comparison', 72, 120);

// Basic strikethrough text
doc.setFont('Helvetica', PdfConstants.STYLE_STRIKETHROUGH);
doc.text('Text with strikethrough formatting', 72, 150);

// Bold strikethrough text
doc.setFont('Helvetica', PdfConstants.STYLE_BOLD_STRIKETHROUGH);
doc.text('Bold text with strikethrough', 72, 180);

// Red strikethrough text
doc.setFont('Helvetica', PdfConstants.STYLE_STRIKETHROUGH);
doc.setTextColor('FF0000'); // Red text and strikethrough
doc.text('Red text with strikethrough', 72, 210);
doc.setTextColor('000000'); // Reset to black

// Save the PDF
doc.save('Strikethrough_Example');
```

### Table Example

```
List<Account> accounts = [SELECT Id, Name, Phone, Industry, Type,
                            BillingStreet, BillingCity, BillingState,
                            BillingPostalCode, BillingCountry, Owner.Name, CreatedDate
                            FROM Account LIMIT 10];

// Create the table data structure - must be Map<String, String> for autoTable
List<Map<String, String>> tableData = new List<Map<String, String>>();

// Add account data rows
for (Account acc : accounts) {
    Map<String, String> dataRow = new Map<String, String>();
    dataRow.put('Name', acc.Name != null ? acc.Name : '');
    dataRow.put('Owner', acc.Owner.Name != null ? acc.Owner.Name : '');
    dataRow.put('CreatedDate', acc.CreatedDate != null ? acc.CreatedDate.format() : '');
    tableData.add(dataRow);
}

// Create PDF
Pdf doc = new Pdf();
doc.text('Account Report', 36, 14);
doc.text('Generated on ' + System.now().format(), 36, 30);

// Define columns
List<AutoTable.Column> columns = new List<AutoTable.Column>();
columns.add(new AutoTable.Column('Name', 'Name'));
columns.add(new AutoTable.Column('Owner', 'Owner'));
columns.add(new AutoTable.Column('CreatedDate', 'CreatedDate'));

// Configure options for striped theme
AutoTable.TableOptions options = new AutoTable.TableOptions();
options.theme = 'STRIPED';
options.startY = doc.getCurrentY() + 20;

// Customize alternate row color for better visibility
options.alternateRowStyles = new Map<String, Object>{
    'fillColor' => 'EAEAEA'  // Slightly darker gray for better contrast
};

// Generate the table output
doc.autoTable(columns, tableData, options);

// Add a watermark to all pages (if needed)
doc.watermark('CONFIDENTIAL');


// Save and return the PDF ID
doc.save('Account_Report_' + System.now().format('yyyy-MM-dd'));
```
