@SuppressWarnings('PMD.EmptyStatementBlock, PMD.NccsMethodCount, PMD.CognitiveComplexity, PMD.ExcessiveParameterList')
/**
 * @description Apex implementation of jsPDF-AutoTable for PDF table generation
 * Both as a data structure for LWC and direct PDF generation
 * @author Ron Hess
 * @since 2025
 */
public with sharing class AutoTable {

    /**
     * @description Column definition for AutoTable
     */
    public class Column {
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String dataKey { get; set; }
        @AuraEnabled
        public Integer width { get; set; }
        @AuraEnabled
        public Map<String, Object> styles { get; set; }

        public Column() {
            this.styles = new Map<String, Object>();
        }

        public Column(String title, String dataKey, Integer width) {
            this(title, dataKey);
            this.width = width;
            this.styles = new Map<String, Object>();
        }

        public Column(String title, String dataKey) {
            this.title = title;
            this.dataKey = dataKey;
            this.styles = new Map<String, Object>();
        }

        public Column withWidth(Integer width) {
            this.width = width;
            return this;
        }

        public Column withStyles(Map<String, Object> styles) {
            this.styles = styles;
            return this;
        }
    }

    /**
     *
     * @description Table options for AutoTable
     */
    // Theme constants for table styles
    public static final String THEME_GRID = 'GRID';
    public static final String THEME_STRIPED = 'STRIPED';

    // Constants for showHead and showFoot options (matching jsPDF-AutoTable)
    public static final String SHOW_EVERY_PAGE = 'everyPage';
    public static final String SHOW_FIRST_PAGE = 'firstPage';
    public static final String SHOW_NEVER = 'never';

    public class TableOptions {
        @AuraEnabled
        public String theme { get; set; }
        @AuraEnabled
        public String showHead { get; set; }
        @AuraEnabled
        public Map<String, Object> styles { get; set; }
        @AuraEnabled
        public Map<String, Object> headStyles { get; set; }
        @AuraEnabled
        public Map<String, Object> bodyStyles { get; set; }
        @AuraEnabled
        public Map<String, Object> alternateRowStyles { get; set; }
        @AuraEnabled
        public Integer startY { get; set; }
        @AuraEnabled
        public Integer margin { get; set; }

        public TableOptions() {
            this.theme = THEME_GRID;
            this.showHead = SHOW_EVERY_PAGE; // Default to showing header on every page
            this.styles = new Map<String, Object>{
                'fontSize' => 8,
                'cellPadding' => 8,  // Increased padding for better readability
                'halign' => 'left',
                'valign' => 'middle'
            };
            this.headStyles = new Map<String, Object>{
                'fillColor' => 'EEEEEE',
                'textColor' => '000000',
                'fontStyle' => 'bold'
            };
            this.bodyStyles = new Map<String, Object>{
                'textColor' => '000000',
                'fillColor' => null
            };
            this.alternateRowStyles = new Map<String, Object>{
                'fillColor' => 'F9F9F9'
            };
            this.margin = 10;
        }

        public TableOptions withStartY(Integer startY) {
            this.startY = startY;
            return this;
        }

        public TableOptions withMargin(Integer margin) {
            this.margin = margin;
            return this;
        }

        public TableOptions withShowHead(String showHead) {
            this.showHead = showHead;
            return this;
        }
    }

    @AuraEnabled
    public List<Column> columns { get; set; }
    @AuraEnabled
    public List<Map<String, String>> body { get; set; }
    @AuraEnabled
    public TableOptions options { get; set; }

    // For direct PDF generation
    private Pdf pdf;

    public AutoTable() {
        this.columns = new List<Column>();
        this.body = new List<Map<String, String>>();
        this.options = new TableOptions();
    }

    /**
     * @description Constructor with PDF document for direct table generation
     * @param pdf The PDF document to draw the table on
     */
    public AutoTable(Pdf pdf) {
        this();
        this.pdf = pdf;
    }

    /**
     * @description Add a column to the table
     * @param title The display title for the column
     * @param dataKey The key used to match data in the body
     */
    public void addColumn(String title, String dataKey) {
        this.columns.add(new Column(title, dataKey));
    }

    /**
     * @description Add a row of data to the table body
     * @param rowData Map of dataKey to cell value
     */
    public void addRow(Map<String, String> rowData) {
        this.body.add(rowData);
    }

    /**
     * @description Example usage of AutoTable
     * @return AutoTable configured with sample data
     */
    @AuraEnabled(cacheable=true)
    public static AutoTable getExample() {
        AutoTable table = new AutoTable();

        // Add columns
        table.addColumn('Name', 'name');
        table.addColumn('Description', 'description');

        // Add rows
        table.addRow(new Map<String, String>{
            'name' => 'Item 1',
            'description' => 'Description for item 1'
        });
        table.addRow(new Map<String, String>{
            'name' => 'Item 2',
            'description' => 'Description for item 2'
        });

        // Customize options if needed
        table.options.showHead = AutoTable.SHOW_EVERY_PAGE;
        table.options.theme = AutoTable.THEME_GRID;

        return table;
    }

    /**
     * helper to add a fieldset to the table,
     * creates a list of columns for the header
     *
     * @param fieldSetName The name of the fieldset to add
     */
    public void addFieldSet(List<FieldSetMember> fieldSet) {
        for (FieldSetMember fieldSetMember : fieldSet) {
            this.addColumn(fieldSetMember.label, fieldSetMember.fieldPath);
        }
    }

    /**
     * given a list of records, add the data to the table body
     * assumes that the columns exist in the table, and
     * keys are correct for the records
     * @param records The list of records to add to the table body
     */
    public void addRecords(List<SObject> records) {
        for (SObject record : records) {
            Map<String, String> rowData = new Map<String, String>();
            for (Column column : this.columns) {
                rowData.put(column.dataKey, (String) record.get(column.dataKey));
            }
            this.body.add(rowData);
        }
    }

    /**
     * @description Draw the table directly to the PDF
     * @return Integer The Y position after the table (for chaining tables)
     */
    /**
     * @description Draws the table with the provided columns, body data, and options
     * @param columns List of Column objects defining the table structure
     * @param body List of row data for the table body
     * @param options Configuration options for the table
     * @return Integer The Y position after drawing the table
     */
    public Integer drawTable(List<Column> columns, List<Map<String, String>> body, TableOptions options) {
        // Store the passed parameters
        this.columns = columns;
        this.body = body;
        this.options = options;

        // Call the standard draw method
        return draw();
    }

    /**
     * @description Draws the table using the current stored columns, body, and options
     * @return Integer The Y position after drawing the table
     */
    public Integer draw() {
        // Validate input
        if (pdf == null) {
            throw new AutoTableException('PDF document not provided for table drawing');
        }

        if (columns == null || columns.isEmpty()) {
            throw new AutoTableException('No columns defined for table');
        }

        // Calculate dimensions
        Map<String, Integer> pageSize = pdf.pageSize();
        Integer tableWidth = pageSize.get('width') - (options.margin * 2);
        Integer startX = options.margin;
        Integer startY = options.startY != null ? options.startY : options.margin;
        Integer currentY = startY;

        // Calculate column widths
        Integer colWidth = tableWidth / columns.size();

        // Draw header row
        Boolean showHeaderOnThisPage = false;

        // Determine if header should be shown based on showHead option
        if (options.showHead == SHOW_EVERY_PAGE) {
            showHeaderOnThisPage = true;
        } else if (options.showHead == SHOW_FIRST_PAGE) {
            // In our current implementation we don't track page numbers
            // so we always show it since we're currently always on the first page
            // TODO: Add proper multi-page support
            showHeaderOnThisPage = true;
        } else if (options.showHead != SHOW_NEVER) {
            // For backward compatibility, treat any other value as everyPage
            showHeaderOnThisPage = true;
        }

        if (showHeaderOnThisPage) {
            Integer headerHeight = 24; // Increased header height for better spacing
            Integer x = startX;
            Integer headerY = currentY;

            // Set theme-specific header styling
            // Use blue background with white text for striped theme
            if (options.theme == THEME_STRIPED) {
                options.headStyles.put('fillColor', '246597'); // Blue color for header
                options.headStyles.put('textColor', 'FFFFFF'); // White text for contrast
            }

            // Apply header styles
            pdf.applyStyles(options.headStyles, false);

            // Draw header cells
            for (Column col : columns) {
                // Draw header cell background with appropriate colors
                PdfRect headerCell = new PdfRect(x, headerY, colWidth, headerHeight, 'F',
                    (String)options.headStyles.get('lineColor'),
                    (String)options.headStyles.get('fillColor'),
                    (Integer)options.headStyles.get('lineWidth'));
                pdf.rect(headerCell);

                // Add header text with proper padding
                Integer cellPadding = (Integer)options.styles.get('cellPadding');
                if (cellPadding == null) {
                    cellPadding = 5;
                }

                // Center the text vertically in the header cell
                Integer textY = headerY + (headerHeight / 2) - 6; // Adjust for text height (approx 12pt)
                pdf.applyStyles(new Map<String, Object>{'textColor' => options.headStyles.get('textColor')}, false);

                // Align text based on settings
                String hAlign = (String)options.styles.get('halign');
                Integer textX = x + cellPadding;

                // If text alignment is center or right, calculate proper position
                if (hAlign == 'center') {
                    // Measure text width (approximate)
                    Integer textWidth = col.title.length() * 6; // Estimate 6px per character
                    textX = x + (colWidth / 2) - (textWidth / 2);
                } else if (hAlign == 'right') {
                    // Measure text width (approximate)
                    Integer textWidth = col.title.length() * 6; // Estimate 6px per character
                    textX = x + colWidth - textWidth - cellPadding;
                }

                // Check if header text needs to be truncated based on column width
                Integer maxTextWidth = colWidth - (cellPadding * 2);
                Integer approxCharWidth = 6; // Approximate width of each character in pixels
                Integer maxChars = maxTextWidth / approxCharWidth;

                String displayText = col.title;
                if (col.title.length() > maxChars) {
                    // Truncate text and add ellipsis
                    displayText = col.title.substring(0, maxChars - 3) + '...';
                }

                pdf.text(displayText, textX, textY);

                // Move to next column
                x += colWidth;
            }

            // Draw grid lines for header
            pdf.applyStyles(new Map<String, Object>{'lineColor' => '000000'}, false);

            // Draw header based on theme
            // Draw the header background with theme-specific styling
            String headerBackgroundColor = (String)options.headStyles.get('fillColor');

            PdfRect headerBackground = new PdfRect(startX, headerY, tableWidth, headerHeight, 'F',
                null,
                headerBackgroundColor,
                0);
            pdf.rect(headerBackground);

            // Apply different header styling based on theme
            if (options.theme == THEME_GRID) {
                // Draw complete header outline for grid theme
                PdfRect headerOutline = new PdfRect(startX, headerY, tableWidth, headerHeight, 'S',
                    (String)options.headStyles.get('lineColor'),
                    null, // Don't fill again, we already did that
                    (Integer)options.headStyles.get('lineWidth'));
                pdf.rect(headerOutline);

                // Draw column dividers for grid theme
                x = startX;
                for (Integer i = 0; i < columns.size() - 1; i++) {
                    x += colWidth;
                    PdfRect divider = new PdfRect(x, headerY, 1, headerHeight, 'S',
                        (String)options.headStyles.get('lineColor'),
                        null,
                        1);
                    pdf.rect(divider);
                }
            } else if (options.theme == THEME_STRIPED) {
                // For striped theme, we don't draw any borders at all
                // Just keep the background colors
            }

            // Move to body rows
            currentY += headerHeight;
        }

        // Draw body rows
        if (body != null && !body.isEmpty()) {
            Integer rowHeight = 20; // Increased row height for better text spacing
            for (Integer rowIdx = 0; rowIdx < body.size(); rowIdx++) {
                Map<String, String> rowData = body[rowIdx];
                Integer x = startX;

                // Apply row styles - alternate rows if specified
                Map<String, Object> rowStyle;
                if (Math.mod(rowIdx, 2) == 1 && options.alternateRowStyles != null) {
                    rowStyle = options.alternateRowStyles;
                } else {
                    rowStyle = options.bodyStyles;
                }
                pdf.applyStyles(rowStyle, false);

                // Draw row background with appropriate colors
                // Only add filled background for alternate rows or if fillColor is explicitly set
                if ((Math.mod(rowIdx, 2) == 1 && options.alternateRowStyles != null) ||
                    (rowStyle.containsKey('fillColor') && rowStyle.get('fillColor') != null)) {
                    PdfRect rowBackground = new PdfRect(startX, currentY, tableWidth, rowHeight, 'F',
                        (String)rowStyle.get('lineColor'),
                        (String)rowStyle.get('fillColor'),
                        (Integer)rowStyle.get('lineWidth'));
                    pdf.rect(rowBackground);
                }

                // Draw cells
                for (Column col : columns) {
                    // Get cell value
                    String cellText = '';
                    if (rowData.containsKey(col.dataKey)) {
                        cellText = rowData.get(col.dataKey);
                    }

                    // Apply body text style
                    pdf.applyStyles(new Map<String, Object>{'textColor' => options.bodyStyles.get('textColor')}, false);

                    // Add cell text with proper padding
                    Integer cellPadding = (Integer)options.styles.get('cellPadding');
                    if (cellPadding == null) {
                        cellPadding = 5;
                    }

                    // Center the text vertically in the cell
                    Integer textY = currentY + (rowHeight / 2) - 6; // Adjust for text height (approx 12pt)

                    // Align text based on settings
                    String hAlign = (String)options.styles.get('halign');
                    Integer textX = x + cellPadding;

                    // If text alignment is center or right, calculate proper position
                    if (hAlign == 'center') {
                        // Measure text width (approximate)
                        Integer textWidth = cellText.length() * 6; // Estimate 6px per character
                        textX = x + (colWidth / 2) - (textWidth / 2);
                    } else if (hAlign == 'right') {
                        // Measure text width (approximate)
                        Integer textWidth = cellText.length() * 6; // Estimate 6px per character
                        textX = x + colWidth - textWidth - cellPadding;
                    }

                    // Check if text needs to be truncated based on column width
                    Integer maxTextWidth = colWidth - (cellPadding * 2);
                    Integer approxCharWidth = 6; // Approximate width of each character in pixels
                    Integer maxChars = maxTextWidth / approxCharWidth;

                    String displayText = cellText;
                    if (cellText.length() > maxChars) {
                        // Truncate text and add ellipsis
                        displayText = cellText.substring(0, maxChars - 3) + '...';
                    }

                    pdf.text(displayText, textX, textY);

                    // Move to next column
                    x += colWidth;
                }

                // Draw cell borders based on theme
                pdf.applyStyles(new Map<String, Object>{'lineColor' => '000000'}, false);

                if (options.theme == THEME_GRID) {
                    // Draw full grid with row outline
                    PdfRect rowOutline = new PdfRect(startX, currentY, tableWidth, rowHeight, 'S',
                        (String)options.bodyStyles.get('lineColor'),
                        null,
                        (Integer)options.bodyStyles.get('lineWidth'));
                    pdf.rect(rowOutline);

                    // Draw column dividers
                    x = startX;
                    for (Integer i = 0; i < columns.size() - 1; i++) {
                        x += colWidth;
                        PdfRect cellDivider = new PdfRect(x, currentY, 1, rowHeight, 'S',
                            (String)options.bodyStyles.get('lineColor'),
                            null,
                            1);
                        pdf.rect(cellDivider);
                    }

                    // Draw row divider for better row separation
                    if (rowIdx < body.size() - 1) {
                        Integer dividerY = currentY + rowHeight;
                        PdfRect rowDivider = new PdfRect(startX, dividerY, tableWidth, 1, 'S',
                            (String)options.bodyStyles.get('lineColor'),
                            null,
                            1);
                        pdf.rect(rowDivider);
                    }
                } else if (options.theme == THEME_STRIPED) {
                    // For striped theme, we don't draw any borders at all (not even outer borders)
                    // The alternating row colors provide sufficient visual separation
                }

                // Move to next row
                currentY += rowHeight;
            }
        }

        // Update the PDF's current Y position
        Integer finalY = currentY + options.margin;
        pdf.setCurrentY(finalY);

        // Return the Y position after the table
        return finalY;
    }

    /**
     * @description Simple example of creating a table from SObject data
     * @param pdf The PDF to add the table to
     * @param sobjects List of SObjects
     * @param fields List of field API names
     * @param fieldLabels Map of field API names to display labels
     * @return Integer The Y position after the table
     */
    public static Integer fromSObjects(Pdf pdf, List<SObject> sobjects, List<String> fields, Map<String, String> fieldLabels) {
        // Create table
        AutoTable table = new AutoTable(pdf);

        // Add columns
        for (String field : fields) {
            String label = fieldLabels.containsKey(field) ? fieldLabels.get(field) : field;
            table.addColumn(label, field);
        }

        // Add rows
        for (SObject record : sobjects) {
            Map<String, String> rowData = new Map<String, String>();
            for (String field : fields) {
                Object value = record.get(field);
                rowData.put(field, value != null ? String.valueOf(value) : '');
            }
            table.addRow(rowData);
        }

        // Draw the table
        return table.draw();
    }

    /**
     * @description AutoTable Exception class
     */
    public class AutoTableException extends Exception {}
}
