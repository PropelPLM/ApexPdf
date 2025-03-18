@SuppressWarnings('PMD.NcssMethodCount, PMD.ExcessiveParameterList, PMD.CognitiveComplexity, PMD.AvoidDebugStatements, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount, PMD.TooManyFields')
/**
 * @description A PDF generation utility class that allows the creation of PDF files directly in
 * Apex without requiring Visualforce. This class implements core
 * PDF 1.7 specification functionality for creating simple PDF documents.
 * inspired by jsPDF
 *
 * @author Ron Hess
 * @since 2025
 * @version 0.9
 * @license MIT
 *
 * @supported
 * JPEG image, Header, Paragraph, Text wrapping, Image, Multi Page, Colors, Styles
 *
 * @wip
 * Tables, Fonts
 *
 * @notsupported
 * Form Field
 *
 * @tests
 * sf apex run test -c -n "AutoTableTest,PdfTest,PdfImageProcessorTest" -r human -w 10
 *
 * @example
    Pdf doc3 = new Pdf();
    doc3.h1('First Page Heading 1', 72, 72);
    doc3.text('Content under heading 1...', 72, null);
    doc3.addPage();
    doc3.h1('Second Page', 72, 72);
    doc3.h2('Secondary Heading', 72, null);
    doc3.h3('Tertiary Heading', 72, null);
    doc3.save('Document TEST3 ' + DateTime.now().getTime());

* @see PdfTest for more examples, see PLM/scripts for more examples
*/

public with sharing class Pdf {
    // Associated classes for PDF generation
    private List<Integer> objectOffsets;
    private List<String> objects;
    private Map<String, Object> documentInfo;
    private List<PdfText> textElements;
    private List<PdfImage> imageElements;
    @testVisible private List<PdfRect> rectElements;
    private Integer currentObjectNumber;
    private Map<String, Integer> imageObjectNumbers;  // Maps image IDs to their object numbers
    private Integer lastY;  // Track the last Y position
    private Integer lastX;  // Track the last X position after text
    private List<List<PdfText>> pageTextElements;  // Text elements for each page
    private List<List<PdfImage>> pageImageElements;  // Image elements for each page
    private List<List<PdfRect>> pageRectElements;  // Rectangle elements for each page

    // Style properties
    private String fillColor = '000000';  // Default black
    private String textColor = '000000';  // Default black
    private String lineColor = '000000';  // Default black
    private Integer lineWidth = 1;        // Default 1pt
    private String fontName = PdfConstants.FONT_HELVETICA;  // Default font (Helvetica)
    private String fontStyle = PdfConstants.STYLE_NORMAL;   // Default style (normal)

    /**
     * @description Set the fill color for subsequent shape operations
     * @param color Hex color string (e.g., '000000' for black)
     * @return This Pdf instance for method chaining
     */
    public Pdf setFillColor(String color) {
        Map<String, Object> styles = new Map<String, Object>{
            'fillColor' => color
        };
        return applyStyles(styles, false);
    }

    /**
     * @description Set the text color for subsequent text operations
     * @param color Hex color string (e.g., '000000' for black)
     * @return This Pdf instance for method chaining
     */
    public Pdf setTextColor(String color) {
        if (color != null && color.trim() != '') {
            String colorTrimmed = color.trim();
            // Ensure it's a valid 6-character hex color
            if (colorTrimmed.length() == 6 && colorTrimmed.isAlphanumeric()) {
                this.textColor = colorTrimmed;
            } else {
                System.debug(LoggingLevel.WARN, 'Invalid text color format: ' + colorTrimmed + '. Using default black.');
                this.textColor = '000000';
            }
        } else {
            this.textColor = '000000';
        }
        return this;
    }

    /**
     * @description Set the line color for subsequent drawing operations
     * @param color Hex color string (e.g., '000000' for black)
     * @return This Pdf instance for method chaining
     */
    public Pdf setLineColor(String color) {
        if (color != null && color.trim() != '') {
            String colorTrimmed = color.trim();
            // Ensure it's a valid 6-character hex color
            if (colorTrimmed.length() == 6 && colorTrimmed.isAlphanumeric()) {
                this.lineColor = colorTrimmed;
            } else {
                System.debug(LoggingLevel.WARN, 'Invalid line color format: ' + colorTrimmed + '. Using default black.');
                this.lineColor = '000000';
            }
        } else {
            this.lineColor = '000000';
        }
        return this;
    }

    /**
     * @description Set the line width for subsequent drawing operations
     * @param width Line width in points
     * @return This Pdf instance for method chaining
     */
    public Pdf setLineWidth(Integer width) {
        if (width != null && width > 0) {
            this.lineWidth = width;
        } else {
            this.lineWidth = 1; // Default to 1 point width
        }
        return this;
    }

    /**
     * @description Set the font and style for subsequent text operations, similar to jsPDF's approach
     * @param fontName Font name, either 'Helvetica' or 'Courier'
     * @param fontStyle Font style: 'normal', 'bold', 'italic', or 'bold italic' (defaults to 'normal')
     * @return This Pdf instance for method chaining
     */
    public Pdf setFont(String fontName, String fontStyle) {
        System.debug(LoggingLevel.FINE, '=== setFont: START ===');
        System.debug(LoggingLevel.FINE, 'Input fontName: ' + fontName + ', fontStyle: ' + fontStyle);

        // Process font name
        if (fontName != null && fontName.trim() != '') {
            String normalizedFont = fontName.trim();
            // Check if it's a supported font family
            if (normalizedFont.equalsIgnoreCase('Helvetica') ||
                normalizedFont.equalsIgnoreCase('Courier')) {
                this.fontName = normalizedFont.substring(0,1).toUpperCase() + normalizedFont.substring(1).toLowerCase();
                System.debug(LoggingLevel.FINE, 'Using font: ' + this.fontName);
            } else {
                System.debug(LoggingLevel.WARN, 'Unsupported font name: ' + normalizedFont + '. Using default Helvetica.');
                this.fontName = PdfConstants.FONT_HELVETICA;
            }
        } else {
            this.fontName = PdfConstants.FONT_HELVETICA;
            System.debug(LoggingLevel.FINE, 'Using default font: ' + this.fontName);
        }

        // Process font style
        if (fontStyle != null && fontStyle.trim() != '') {
            String normalizedStyle = fontStyle.trim().toLowerCase();
            if (normalizedStyle == 'bold') {
                this.fontStyle = PdfConstants.STYLE_BOLD;
                System.debug(LoggingLevel.FINE, 'Setting BOLD style');
            } else if (normalizedStyle == 'italic') {
                this.fontStyle = PdfConstants.STYLE_ITALIC;
                System.debug(LoggingLevel.FINE, 'Setting ITALIC style');
            } else if (normalizedStyle == 'bold italic' || normalizedStyle == 'bolditalic' || normalizedStyle == 'bold-italic') {
                this.fontStyle = PdfConstants.STYLE_BOLD_ITALIC;
                System.debug(LoggingLevel.FINE, 'Setting BOLD-ITALIC style');
            } else {
                this.fontStyle = PdfConstants.STYLE_NORMAL;
                System.debug(LoggingLevel.FINE, 'Setting NORMAL style');
            }
        } else {
            this.fontStyle = PdfConstants.STYLE_NORMAL;
            System.debug(LoggingLevel.FINE, 'Setting default NORMAL style');
        }

        System.debug(LoggingLevel.FINE, 'Final font: ' + this.fontName + ', style: ' + this.fontStyle);
        System.debug(LoggingLevel.FINE, '=== setFont: END ===');
        return this;
    }

    /**
     * @description Set the font for subsequent text operations (overloaded without style parameter)
     * @param fontName Font name, either 'Helvetica' or 'Courier'
     * @return This Pdf instance for method chaining
     */
    public Pdf setFont(String fontName) {
        return setFont(fontName, PdfConstants.STYLE_NORMAL);
    }

    /**
     * @description Get the current font name
     * @return The current font name being used
     */
    public String getFontName() {
        return this.fontName;
    }

    /**
     * @description Get the current font style
     * @return The current font style being used
     */
    public String getFontStyle() {
        return this.fontStyle;
    }

    // Review constants from PdfConstants class

    // Text positioning
    private Integer currentPageNum;  // Current page number
    private List<Integer> pageObjectNumbers;  // Object numbers for each page
    private Integer contentStreamStart;  // Base object number for content streams

    /**
     * @description Apply styles to the PDF for drawing operations
     * @param styles Map of style properties to apply
     * @param fontOnly If true, only apply font-related styles
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf applyStyles(Map<String, Object> styles, Boolean fontOnly) {
        // In a full implementation, this would handle font style, size, etc.
        // For now, we'll just handle the basic styles that we need for table drawing

        if (styles.containsKey('fillColor')) {
            this.fillColor = (String)styles.get('fillColor');
        }

        if (!fontOnly && styles.containsKey('textColor')) {
            this.textColor = (String)styles.get('textColor');
        }

        if (!fontOnly && styles.containsKey('lineColor')) {
            this.lineColor = (String)styles.get('lineColor');
        }

        if (!fontOnly && styles.containsKey('lineWidth')) {
            this.lineWidth = (Integer)styles.get('lineWidth');
        }

        return this;
    }

    /**
     * @description Adds a rectangle to the PDF
     * @param x X-coordinate in points from left edge
     * @param y Y-coordinate in points from top edge
     * @param width Width in points
     * @param height Height in points
     * @param fillStyle Fill style ('S' for stroke, 'F' for fill, 'B' for both)
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf rect(Integer x, Integer y, Integer width, Integer height, String fillStyle) {
        // Create a rectangle object
        PdfRect rect = new PdfRect(x, y, width, height, fillStyle, lineColor, fillColor, lineWidth);

        // Add it to the current page's rectangle elements
        this.rectElements.add(rect);

        return this;
    }

    /**
     * @description Adds a rectangle to the PDF with full styling control
     * @param rect A PdfRect object with all required styling and positioning
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf rect(PdfRect rect) {
        // Add it to the current page's rectangle elements
        this.rectElements.add(rect);

        return this;
    }

    /**
     * @description Draws a line from (x1,y1) to (x2,y2)
     * @param x1 X-coordinate of starting point
     * @param y1 Y-coordinate of starting point
     * @param x2 X-coordinate of ending point
     * @param y2 Y-coordinate of ending point
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf line(Integer x1, Integer y1, Integer x2, Integer y2) {
        // For a line, we'll create a very thin rectangle that goes from point 1 to point 2
        // Calculate width and height based on the points
        Integer width = Math.abs(x2 - x1);
        Integer height = Math.abs(y2 - y1);

        // Handle horizontal line
        if (height == 0) {
            Integer x = Math.min(x1, x2);
            PdfRect rect = new PdfRect(x, y1, width, lineWidth, 'F', lineColor, lineColor, lineWidth);
            this.rectElements.add(rect);
            return this;
        }

        // Handle vertical line
        if (width == 0) {
            Integer y = Math.min(y1, y2);
            PdfRect rect = new PdfRect(x1, y, lineWidth, height, 'F', lineColor, lineColor, lineWidth);
            this.rectElements.add(rect);
            return this;
        }

        // For diagonal lines, we'll approximate with a series of small rectangles
        // This approach avoids relying on direct PDF content stream commands

        // Calculate the angle and distance
        Double dx = x2 - x1;
        Double dy = y2 - y1;
        Double distance = Math.sqrt(dx * dx + dy * dy);

        // Number of steps to create a smooth line
        Integer steps = Math.max(Math.abs(Integer.valueOf(distance)), 10);

        // Draw a series of small rectangles along the line path
        for (Integer i = 0; i < steps; i++) {
            Double ratio = i / (Double)steps;
            Integer dotX = Integer.valueOf(x1 + (ratio * dx));
            Integer dotY = Integer.valueOf(y1 + (ratio * dy));

            // Create a small rectangle at this point
            PdfRect dot = new PdfRect(
                dotX, dotY, lineWidth, lineWidth,
                'F', lineColor, lineColor, lineWidth
            );
            this.rectElements.add(dot);
        }

        // Add one final dot at the exact endpoint
        PdfRect endDot = new PdfRect(
            x2, y2, lineWidth, lineWidth,
            'F', lineColor, lineColor, lineWidth
        );
        this.rectElements.add(endDot);

        return this;
    }

    /**
     * @description Get the page size of the PDF
     * @return Map<String, Integer> Map containing width and height of the page in points
     */
    public Map<String, Integer> pageSize() {
        return new Map<String, Integer>{
            'width' => PdfConstants.PAGE_WIDTH,
            'height' => PdfConstants.PAGE_HEIGHT
        };
    }

    /**
     * @description Options for text rendering
     */
    public class TextOptions {
        public Integer maxWidth;
        public Integer fontSize;
        public String fontStyle;

        /**
         * Controls where wrapped lines should begin (X position)
         * When null (default), wrapped lines maintain the original X position - ideal for columns
         * When set to a specific value (like PdfConstants.PAGE_MARGIN), wrapped lines
         * will start at that position - ideal for traditional paragraphs
         */
        public Integer wrapToXPosition;

        public TextOptions() {
            this.fontSize = PdfConstants.DEFAULT_FONT_SIZE;
            this.fontStyle = PdfConstants.STYLE_NORMAL;
        }
    }

    /**
     * @description Constructor initializes a new PDF document with default settings
     */
    public Pdf() {

        // Initialize basic properties
        this.objectOffsets = new List<Integer>();
        this.objects = new List<String>();
        this.documentInfo = new Map<String, Object>{
            'Producer' => UserInfo.getName(),
            'Creator' => UserInfo.getName(),
            'CreationDate' => Datetime.now()
        };

        // Initialize text and image tracking
        this.textElements = new List<PdfText>();
        this.imageElements = new List<PdfImage>();
        this.rectElements = new List<PdfRect>();
        this.imageObjectNumbers = new Map<String, Integer>();

        // Initialize page tracking
        this.pageTextElements = new List<List<PdfText>>();
        this.pageImageElements = new List<List<PdfImage>>();
        this.pageRectElements = new List<List<PdfRect>>();
        this.pageObjectNumbers = new List<Integer>();
        this.contentStreamStart = PdfConstants.FIRST_PAGE_OBJ_NUM + 1; // Initialize content stream start

        // Initialize counters and positions
        this.currentObjectNumber = 1;
        this.currentPageNum = 1;
        this.lastY = PdfConstants.PAGE_MARGIN;

        // Initialize first page
        this.pageObjectNumbers.add(0);  // Placeholder, will be updated when page is written
        this.pageTextElements.add(new List<PdfText>());  // Initialize first page's text elements
        this.pageImageElements.add(new List<PdfImage>());  // Initialize first page's image elements
        this.pageRectElements.add(new List<PdfRect>());  // Initialize first page's rectangle elements

    }



    /**
     * @description Get line height based on font size and style
     * @param options TextOptions containing font size and style
     * @return Integer line height in points
     */
    public Integer getLineHeight(TextOptions options) {
        // Delegate to PdfTextProcessor
        return PdfTextProcessor.getLineHeight(options);
    }

    /**
     * @description Adds a new page to the PDF document
     * @return The current Pdf instance for method chaining
     */
    public Pdf addPage() {
        // Store current page's elements if not empty
        if (!textElements.isEmpty() || !imageElements.isEmpty() || !rectElements.isEmpty()) {
            // Copy current elements to page arrays
            pageTextElements.set(currentPageNum - 1, new List<PdfText>(textElements));
            pageImageElements.set(currentPageNum - 1, new List<PdfImage>(imageElements));
            pageRectElements.set(currentPageNum - 1, new List<PdfRect>(rectElements));
        }

        // Clear page content for next page
        textElements.clear();
        imageElements.clear();
        rectElements.clear();
        imageObjectNumbers.clear();
        lastY = PdfConstants.PAGE_MARGIN;
        currentPageNum++;

        // Initialize arrays for new page
        pageTextElements.add(new List<PdfText>());
        pageImageElements.add(new List<PdfImage>());
        pageRectElements.add(new List<PdfRect>());
        pageObjectNumbers.add(0);  // Placeholder, will be updated when page is written

        return this;
    }

    /**
     * @description Gets the current Y position for text placement
     * @return Integer Y position in points from top of page
     */
    public Integer getCurrentY() {
        return this.lastY;
    }

    /**
     * @description Returns the current X position after the last rendered text
     * @return The X position in points
     */
    public Integer getCurrentX() {
        return this.lastX != null ? this.lastX : PdfConstants.PAGE_MARGIN;
    }

    /**
     * @description Sets the current Y position
     * @param y The new Y position
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf setCurrentY(Integer y) {
        this.lastY = y;
        return this;
    }

    /**
     * @description Approximate the width of text using the current font
     * @param text The text to measure
     * @return TextMetrics object containing width and other metrics
     */
    public TextMetrics measureText(String text) {
        if (text == null || text == '') {
            return new TextMetrics(0, 0);
        }

        // Use default font size of 12pt if not specified in the context
        Integer fontSize = PdfConstants.DEFAULT_FONT_SIZE;

        // This is a simple approximation using a fixed width-per-character approach
        // For more accuracy, we would need to use the actual font metrics
        Double charWidth;

        // Adjust width based on font family and style
        String fontName = PdfConstants.FONT_HELVETICA; // Default Helvetica font
        if (fontName == PdfConstants.FONT_COURIER) {
            // Courier is a monospace font - all characters have the same width
            charWidth = 0.6 * fontSize;
        } else {
            // Helvetica is a proportional font - approximate average width
            charWidth = 0.5 * fontSize;
        }

        // Adjust width based on font style (use default if not specified)
        String fontStyle = PdfConstants.STYLE_NORMAL; // Default normal style
        if (fontStyle == PdfConstants.STYLE_BOLD ||
            fontStyle == PdfConstants.STYLE_BOLD_ITALIC) {
            // Bold text is slightly wider
            charWidth *= 1.1;
        }

        Integer width = Math.round(charWidth * text.length());
        return new TextMetrics(width, fontSize);
    }

    /**
     * @description Class to hold text measurement information
     */
    public class TextMetrics {
        public Integer width { get; private set; }
        public Integer height { get; private set; }

        public TextMetrics(Integer width, Integer height) {
            this.width = width;
            this.height = height;
        }
    }

    /**
     * @description Adds text to the PDF at specified coordinates with options
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @param options Optional text rendering options (maxWidth for text wrapping)
     * @return The current Pdf instance for method chaining
     */
    public Pdf text(String text, Integer x, Integer y, TextOptions options) {
        // Basic validation
        if (text == null || text.trim() == '') {
            System.debug(LoggingLevel.WARN, 'Empty text skipped.');
            return this;
        }

        // Store current text color to apply to processed elements
        String currentTextColor = this.textColor;

        // Process text using PdfTextProcessor - note this only creates basic text elements
        // We will modify them below to apply current document font settings
        List<PdfText> processedElements = PdfTextProcessor.processText(text, x, y, options, this.lastY);

        // CRITICAL: Apply current text color and font settings to all processed elements

        for (Integer i = 0; i < processedElements.size(); i++) {
            PdfText element = processedElements[i];
            String originalText = element.text; // Keep this for debug log only

            // Always set text color to current document color
            element.textColor = currentTextColor;

            // Always set font name to current document font
            element.fontName = this.fontName;

            // For font style, prefer options if specified, otherwise use document level
            if (options != null && options.fontStyle != null) {
                element.fontStyle = options.fontStyle;
            } else {
                element.fontStyle = this.fontStyle;
            }

            // Replace the element in the list with our updated version
            processedElements[i] = element;

            // Element styling complete
        }

        // Handle page breaks if needed
        // Track if any elements caused a line break
        Boolean hasLineBreak = false;
        Integer lastLineY = 0;

        for (Integer i = 0; i < processedElements.size(); i++) {
            PdfText element = processedElements[i];

            if (element.needsPageBreak) {
                addPage();
                // Reprocess with new page position
                return text(text, x, PdfConstants.PAGE_MARGIN, options);
            }

            // Add element to our collection
            textElements.add(element);
            pageTextElements.get(currentPageNum - 1).add(element);

            // Track the Y position of this element
            if (i == 0 || element.y > lastLineY) {
                lastLineY = element.y;
                hasLineBreak = true;
            }
        }

        // Only update the lastY position if there was a natural line break in the text
        // This keeps styled text runs (bold, italic) inline within the same paragraph
        Boolean shouldUpdateY = hasLineBreak;

        // Calculate final X position after all text elements
        if (processedElements.size() > 0) {
            PdfText lastElement = processedElements[processedElements.size() - 1];

            // Calculate the final X position based on the last text element

            // Estimate the ending X position based on text width
            Integer textWidth = PdfTextProcessor.estimateTextWidth(lastElement.text, options);
            Integer oldLastX = this.lastX;
            lastX = lastElement.x + textWidth;

            // IMPORTANT: Update the X position for continued text flow within the same paragraph
            // Always calculate the ending X position for proper text flow
            Integer endingX = lastElement.x + textWidth;

            // Calculate the ending X position for proper text flow
            // This will be used by subsequent text in the same line

            // Update positions based on whether this is a continuation and if we need a new line
            if (shouldUpdateY) {
                // Line break occurred - start new line
                Integer lineHeight = PdfTextProcessor.getLineHeight(options);
                // Use the last element's Y position as the base for the next line
                lastY = lastElement.y + lineHeight;

                // Reset X position to the default left margin since we're moving to a new line
                lastX = PdfConstants.PAGE_MARGIN;
            } else {
                // No line break - continue on same line
                // Always update lastX to ensure proper flow between text runs
                lastX = endingX;
            }
        }
        return this;
    }

    /**
     * @description Adds text to the PDF at specified coordinates
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @return The current Pdf instance for method chaining
     */
    public Pdf text(String text, Integer x, Integer y) {
        if (y == null && this.lastY != null) {
            y = this.lastY + getLineHeight(new TextOptions());
        } else if (y == null) {
            y = PdfConstants.PAGE_MARGIN;  // Default to top margin if no lastY
        }
        TextOptions options = new TextOptions();
        options.maxWidth = PdfConstants.PAGE_WIDTH - (PdfConstants.PAGE_MARGIN * 2);

        // Propagate current font style to the options
        // This fixes the issue with italic and bold styles not being maintained
        options.fontStyle = this.fontStyle;

        // By default, maintain X position for wrapped lines (column-aware behavior)
        // Leave options.wrapToXPosition as null to maintain the current X position

        return text(text, x, y, options);
    }


    /**
     * @description Helper method for creating headings with different sizes
     * @param headingLevel The heading level (1, 2, or 3) used for logging
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @param fontSize The font size for this heading
     * @return The current Pdf instance for method chaining
     */
    private Pdf heading(Integer headingLevel, String text, Integer x, Integer y, Integer fontSize) {

        TextOptions options = new TextOptions();
        options.maxWidth = PdfConstants.PAGE_WIDTH - (PdfConstants.PAGE_MARGIN * 2);
        options.fontSize = fontSize;
        options.fontStyle = PdfConstants.STYLE_BOLD;


        return text(text, x, y, options);
    }

    /**
     * @description Adds heading 1 text to the PDF at specified coordinates
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @return The current Pdf instance for method chaining
     */
    public Pdf h1(String text, Integer x, Integer y) {
        return heading(1, text, x, y, PdfConstants.H1_FONT_SIZE);
    }

    /**
     * @description Adds heading 2 text to the PDF at specified coordinates
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @return The current Pdf instance for method chaining
     */
    public Pdf h2(String text, Integer x, Integer y) {
        return heading(2, text, x, y, PdfConstants.H2_FONT_SIZE);
    }

    /**
     * @description Adds heading 3 text to the PDF at specified coordinates
     * @param text The text to add to the PDF
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @return The current Pdf instance for method chaining
     */
    public Pdf h3(String text, Integer x, Integer y) {
        return heading(3, text, x, y, PdfConstants.H3_FONT_SIZE);
    }

    /**
     * @description Gets the current Y position after the last text element
     * @return The Y coordinate in points
     */
    public Integer currentY() {
        return this.lastY;
    }

    /**
     * @description Ensures that the page arrays have enough capacity for the given page number
     * @param pageNum The page number to ensure capacity for (1-based)
     */
    private void ensurePageCapacity(Integer pageNum) {
        // Make sure our page arrays have enough capacity
        while (pageTextElements.size() < pageNum) {
            pageTextElements.add(new List<PdfText>());
        }

        while (pageImageElements.size() < pageNum) {
            pageImageElements.add(new List<PdfImage>());
        }
    }

    /**
     * @description Adds an image to the PDF
     * @param imageData The image data as a Blob
     * @param format Image format ('JPEG' or 'PNG')
     * @param x X coordinate for image placement
     * @param y Y coordinate for image placement
     * @param width Width to display the image
     * @param height Height to display the image
     * @return The current Pdf instance for method chaining
     */
    public Pdf addImage(Blob imageData, String format, Integer x, Integer y, Integer width, Integer height) {
        // Create a unique image ID that will be referenced in the PDF
        String imageId = 'Im' + (imageElements.size() + 1);

        // CRITICAL: Normalize the format to handle inconsistencies
        String normalizedFormat = (format != null) ? format.toUpperCase() : PdfConstants.FORMAT_JPEG;

        // Default to JPEG for common types or if missing
        if (normalizedFormat == 'JPG' || normalizedFormat == '') {
            normalizedFormat = PdfConstants.FORMAT_JPEG;
        }

        //System.debug('Original format: ' + format + ', Normalized to: ' + normalizedFormat);

        // Create the image element
        PdfImage imageElement = new PdfImage(imageId, normalizedFormat, imageData, x, y, width, height);

        // Add to the global collection
        imageElements.add(imageElement);

        // Add to the current page's collection
        ensurePageCapacity(currentPageNum);
        if (pageImageElements[currentPageNum - 1] == null) {
            pageImageElements[currentPageNum - 1] = new List<PdfImage>();
        }
        pageImageElements[currentPageNum - 1].add(imageElement);

        // Log detailed information for debugging
        //System.debug('Added image with ID ' + imageId + ' at position (' + x + ',' + y + ') with dimensions ' +
                    //width + 'x' + height + ' to page ' + currentPageNum);
        //System.debug('Format: ' + format + ', Size: ' + imageData.size() + ' bytes');
        return this;
    }


    private String writeImage(PdfImage image) {
        // Use the assigned object number for this image
        Integer objNum = imageObjectNumbers.get(image.imageId);

        // Delegate image writing to PdfImageProcessor
        return PdfImageProcessor.writeImage(image, objNum);
    }

    private String writeContents(List<PdfText> pageText, List<PdfImage> pageImages, Integer pageIndex) {
        String stream = '';

        // Process rectangle elements first
        List<PdfRect> pageRects = pageIndex < pageRectElements.size() ? pageRectElements[pageIndex] : new List<PdfRect>();
        if (pageRects != null && !pageRects.isEmpty()) {

            // Add rectangle drawing operations
            for (PdfRect rect : pageRects) {
                String rectCmd = rect.toPdfCommand();
                stream += rectCmd + '\n';

            }
        }

        // Add text elements
        if (pageText != null && !pageText.isEmpty()) {

            stream += 'BT\n';  // Begin text block
            String currentFont = null;
            Integer currentFontSize = null;

            // Set default text color to black
            stream += '0 0 0 rg\n';  // Set RGB color for text to black

            for(PdfText element : pageText) {

                String textPreview = element.text.length() > 20 ? element.text.substring(0, 20) + '...' : element.text;
                // System.debug(LoggingLevel.ERROR, '**** PROCESSING TEXT: ' + textPreview);

                // Determine font style suffix for debug info and resources
                String fontStyleSuffix = '';
                if (element.fontStyle == PdfConstants.STYLE_BOLD) {
                    fontStyleSuffix = '-Bold';
                } else if (element.fontStyle == PdfConstants.STYLE_ITALIC) {
                    fontStyleSuffix = '-Italic';
                } else if (element.fontStyle == PdfConstants.STYLE_BOLD_ITALIC) {
                    fontStyleSuffix = '-BoldItalic';
                }

                // Add font name and style as a debug comment in the PDF itself
                String fontDebugInfo = '% DEBUG-FONT: ' + element.fontName + fontStyleSuffix + '\n';
                stream += fontDebugInfo;

                // Map font name and style to PDF font resource name
                String fontResource;

                // Debug output


                // Direct comparison with constants instead of string comparison
                Boolean isBold = element.fontStyle == PdfConstants.STYLE_BOLD;
                Boolean isItalic = element.fontStyle == PdfConstants.STYLE_ITALIC;
                Boolean isBoldItalic = element.fontStyle == PdfConstants.STYLE_BOLD_ITALIC;



                // Map to font resources - using resource naming scheme F1-F8
                // F1: Helvetica, F2: Helvetica-Bold, F5: Helvetica-Italic, F6: Helvetica-BoldItalic
                // F3: Courier, F4: Courier-Bold, F7: Courier-Italic, F8: Courier-BoldItalic
                if (element.fontName == PdfConstants.FONT_COURIER) {
                    if (isBoldItalic) {
                        fontResource = 'F8';  // Courier-BoldItalic
                    } else if (isItalic) {
                        fontResource = 'F7';  // Courier-Italic
                    } else if (isBold) {
                        fontResource = 'F4';  // Courier-Bold
                    } else {
                        fontResource = 'F3';  // Courier
                    }
                } else { // Default to Helvetica
                    if (isBoldItalic) {
                        fontResource = 'F6';  // Helvetica-BoldItalic
                    } else if (isItalic) {
                        fontResource = 'F5';  // Helvetica-Italic
                    } else if (isBold) {
                        fontResource = 'F2';  // Helvetica-Bold
                    } else {
                        fontResource = 'F1';  // Helvetica
                    }
                }



                // Always set the font for clarity in debugging
                // Set font if it changed
                // if (currentFont != fontResource || currentFontSize != element.fontSize) {
                    String fontDebugMsg = '% FONT-INFO: ' + element.fontName + (element.fontStyle == PdfConstants.STYLE_BOLD ? '-Bold' : '') +
                                      ' with style=' + element.fontStyle + ' mapped to resource=' + fontResource + '\n';
                    stream += fontDebugMsg;

                    String fontCmd = '/' + fontResource + ' ' + element.fontSize + ' Tf\n';
                    stream += fontCmd;

                    currentFont = fontResource;
                    currentFontSize = element.fontSize;
                // }

                // Apply text color - convert hex color to RGB values (0-1)
                String colorToUse = '000000'; // Default to black

                // Validate text color format - should be a 6-character hex string
                if (element.textColor != null && element.textColor.trim() != '') {
                    String color = element.textColor.trim();
                    // Ensure it's a valid 6-character hex color
                    if (color.length() == 6 && color.isAlphanumeric()) {
                        colorToUse = color;
                    }
                }

                // Parse hex color and convert to RGB values between 0 and 1
                // Convert hex to decimal manually since Apex doesn't have Integer.valueOf(String, radix)
                Decimal r = hexToDecimal(colorToUse.substring(0, 2)) / 255.0;
                Decimal g = hexToDecimal(colorToUse.substring(2, 4)) / 255.0;
                Decimal b = hexToDecimal(colorToUse.substring(4, 6)) / 255.0;

                // Format as plain string to avoid scientific notation
                String rStr = r.toPlainString();
                String gStr = g.toPlainString();
                String bStr = b.toPlainString();

                stream += rStr + ' ' + gStr + ' ' + bStr + ' rg\n';  // Set RGB color for text

                // Position text using text matrix (Tm)
                // PDF coordinates start from bottom-left, so we need to transform Y
                Integer pdfY = PdfConstants.PAGE_HEIGHT - element.y - element.fontSize;
                stream += '1 0 0 1 ' + element.x + ' ' + pdfY + ' Tm\n';
                stream += '(' + escapePdfString(element.text) + ') Tj\n';
            }
            stream += 'ET\n';  // End text block
        }

        // Add image elements
        if (pageImages != null && !pageImages.isEmpty()) {
            for(PdfImage image : pageImages) {
                // Register this image for processing (actual object will be written later)
                if (!imageObjectNumbers.containsKey(image.imageId)) {
                    // CRITICAL: Assign a fixed, predictable object number for images
                    // We'll use 100 + images index to avoid conflicts with page and content objects
                    Integer imageObjNum = 100 + imageObjectNumbers.size() + 1;
                    imageObjectNumbers.put(image.imageId, imageObjNum);

                }

                // Calculate position (PDF coordinates start from bottom-left)
                Integer pdfY = PdfConstants.PAGE_HEIGHT - image.y - image.height;

                // CRITICAL FIX: Build image drawing instructions with proper scale and positioning
                // q - Save graphics state
                // cm - Concatenate matrix (sets image transformation: width, height, position)
                // Do - Draw the XObject
                // Q - Restore graphics state

                // Make sure scale is properly set (if width/height are 0, default to 1)
                Integer imgWidth = (image.width > 0) ? image.width : 100;
                Integer imgHeight = (image.height > 0) ? image.height : 100;

                // Draw commands with proper positioning
                String drawCommands = 'q\n' +
                                   // Scale and rotation matrix - width, height, position
                                   String.valueOf(imgWidth) + ' 0 0 ' + String.valueOf(imgHeight) + ' ' +
                                   String.valueOf(image.x) + ' ' + String.valueOf(pdfY) + ' cm\n' +
                                   // CRITICAL: The XObject name MUST match the name in Resources dictionary
                                   '/' + image.imageId + ' Do\n' +
                                   'Q\n';

                // Add BT/ET to ensure any state changes don't affect text
                drawCommands = 'BT\nET\n' + drawCommands;

                // Add the commands to the content stream
                stream += drawCommands;

                // Log details for debugging
                // System.debug('Added image drawing instructions:\n' + drawCommands.replace('\n', ' '));
                // System.debug('Content stream now has length: ' + stream.length());

                // System.debug('Added image reference to content stream: /' + image.imageId + ' Do at position (' +
                //            image.x + ',' + pdfY + ') with dimensions ' + image.width + 'x' + image.height);
            }
        }

        return stream;
    }

    /**
     * @description Writes the cross-reference table for all PDF objects
     * @return String containing the PDF xref table
     */
    private String writeXref() {
        // Start xref table
        String xref = 'xref\r\n0 ' + String.valueOf(currentObjectNumber) + '\r\n';
        xref += '0000000000 65535 f\r\n';

        // Add entries for all objects (1-based)
        for (Integer i = 0; i < objectOffsets.size(); i++) {
            String offsetStr = String.valueOf(objectOffsets[i]).leftPad(10, '0');
            xref += offsetStr + ' 00000 n\r\n';
        }

        return xref;
    }

    /**
     * @description Writes the PDF trailer with document root information
     * @return String containing the PDF trailer
     */
    private String writeTrailer() {
        // Calculate startxref position (header + all objects)
        Integer startxref = 0;
        for (Integer offset : objectOffsets) {
            startxref = Math.max(startxref, offset);
        }

        // Add trailer dictionary with required entries
        String trailer = 'trailer\r\n'
                      + '<<\r\n'
                      + '/Size ' + String.valueOf(currentObjectNumber) + '\r\n'
                      + '/Root 1 0 R\r\n'
                      + '/Info <<\r\n'
                      + '/Producer (' + escapePdfString(String.valueOf(documentInfo.get('Producer'))) + ')\r\n'
                      + '/Creator (' + escapePdfString(String.valueOf(documentInfo.get('Creator'))) + ')\r\n'
                      + '/CreationDate (D:' + ((Datetime)documentInfo.get('CreationDate')).format('yyyyMMddHHmmss') + 'Z)\r\n'
                      + '>>\r\n'
                      + '>>\r\n'
                      + 'startxref\r\n'
                      + String.valueOf(startxref) + '\r\n'
                      + '%%EOF';

        return trailer;
    }

    /**
     * @description Escapes special characters in text for PDF compatibility
     * @param text The text to escape
     * @return String with escaped special characters
     */
    private String escapePdfString(String text) {
        return text.replace('\\', '\\\\')
                  .replace('(', '\\(')
                  .replace(')', '\\)');
    }

    /**
     * @description Creates and renders a table in the PDF document
     * @param columns List of Column objects defining the table structure
     * @param body List of row data for the table body
     * @param options Optional configuration for the table
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf autoTable(List<AutoTable.Column> columns, List<Map<String, String>> body, AutoTable.TableOptions options) {
        AutoTable table = new AutoTable(this);
        table.drawTable(columns, body, options);
        return this;
    }

    /**
     * @description Creates and renders a table in the PDF document with default options
     * @param columns List of Column objects defining the table structure
     * @param body List of row data for the table body
     * @return Pdf The current PDF instance for method chaining
     */
    public Pdf autoTable(List<AutoTable.Column> columns, List<Map<String, String>> body) {
        return autoTable(columns, body, new AutoTable.TableOptions());
    }

    /**
     * @description Generates the final PDF document and saves it as a ContentDocument
     * @param filename The name to give the PDF file (without extension)
     * @return Id The ID of the ContentDocument created
     */
    public Id save(String filename) {
        // Ensure the last page's elements are saved properly
        if (!textElements.isEmpty() || !imageElements.isEmpty() || !rectElements.isEmpty()) {
            pageTextElements.set(currentPageNum - 1, new List<PdfText>(textElements));
            pageImageElements.set(currentPageNum - 1, new List<PdfImage>(imageElements));
            pageRectElements.set(currentPageNum - 1, new List<PdfRect>(rectElements));
        }

        // Reset object tracking
        objects = new List<String>();
        objectOffsets = new List<Integer>();
        // System.debug(LoggingLevel.INFO, '== Pdf.save after reset: Heap size = ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize() + ' bytes');
        currentObjectNumber = 1;

        // Start building PDF with header
        PdfStream stream = new PdfStream( PdfConstants.PDF_HEADER, PdfConstants.PDF_HEADER.length());

        // STEP 1: Create and write catalog (always object 1)
        stream.createCatalogObject(objectOffsets);

        // STEP 2: Create and write pages dictionary (always object 2) with image resources
        stream.createPagesObjectWithImages(objectOffsets, currentPageNum, imageElements, imageObjectNumbers);

        // STEP 3: Generate content streams first to get their object numbers
        Map<String, List<Object>> contentData = generateContentStreams();
        List<String> contentStreams = (List<String>)contentData.get('contentStreams');
        List<Boolean> hasContent = (List<Boolean>)contentData.get('hasContent');
        List<Integer> contentStreamObjects = (List<Integer>)contentData.get('contentStreamObjects');

        // STEP 4: Write all page objects with content stream references
        stream = createPageObjects(stream, contentData, objectOffsets);

        // STEP 5: Write all content stream objects
        for (Integer i = 0; i < currentPageNum; i++) {
            if (hasContent[i]) {
                String content = contentStreams[i];
                Integer contentObjNum = contentStreamObjects[i];

                // Debug information about content stream
                Boolean hasImageRefs = content.contains(' Do');
                // System.debug('Content stream for page ' + (i+1) + ' with length ' + content.length() +
                //            ' has image references: ' + hasImageRefs);

                // Output a sample of the content stream
                if (hasImageRefs) {
                    String debugStream = content.replace('\n', ' ').replace('\r', ' ');
                    if (debugStream.length() > 200) {
                        debugStream = debugStream.substring(0, 200) + '... (truncated)';
                    }
                    // System.debug('Content stream with image references (preview): ' + debugStream);
                }

                // Make extra sure newlines are consistent in content stream
                content = content.replace('\n', '\r\n');

                // Create content stream object
                String contentObj = contentObjNum + ' 0 obj' + PdfConstants.LINE_BREAK
                                 + PdfConstants.DICT_START
                                 + '/Length ' + content.length() + PdfConstants.LINE_BREAK
                                 + PdfConstants.DICT_END
                                 + PdfConstants.STREAM_START
                                 + content
                                 + PdfConstants.STREAM_END
                                 + PdfConstants.OBJ_END;

                stream.appendContent(contentObj, objectOffsets);
                currentObjectNumber = Math.max(currentObjectNumber, contentObjNum + 1);
            }
        }

        // STEP 6: Write image objects if we have any
        if (!imageElements.isEmpty()) {
            // System.debug('Writing ' + imageElements.size() + ' image objects');
            for (PdfImage image : imageElements) {
                if (imageObjectNumbers.containsKey(image.imageId)) {
                    // Use the pre-assigned object number
                    Integer imageObjNum = imageObjectNumbers.get(image.imageId);

                    // Make sure our current object number is updated properly
                    currentObjectNumber = Math.max(currentObjectNumber, imageObjNum + 1);

                    // Generate image object with its assigned number
                    String imageObj = writeImage(image);
                    stream.appendContent(imageObj, objectOffsets);
                }
            }
        }

        // STEP 7: Write xref table
        Integer heapSizeBeforeXref = Limits.getHeapSize();
        Integer heapLimit = Limits.getLimitHeapSize();
        Decimal percentUsed = (heapSizeBeforeXref * 100.0) / heapLimit;
        // System.debug(LoggingLevel.FINE, '== MEMORY STATS == Before xref: Heap = ' + heapSizeBeforeXref + ' / ' + heapLimit + ' bytes (' + percentUsed.setScale(2) + '% used)');
        String xref = writeXref();
        stream.pdfContent += xref;

        // STEP 8: Write trailer
        // System.debug(LoggingLevel.FINE, '== Pdf.save before writeTrailer: Heap size = ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize() + ' bytes');
        String trailer = writeTrailer();
        stream.pdfContent += trailer;
        Integer streamSize = stream.pdfContent.length();
        Integer heapBeforeSave = Limits.getHeapSize();
        heapLimit = Limits.getLimitHeapSize();
        percentUsed = (heapBeforeSave * 100.0) / heapLimit;
        // System.debug(LoggingLevel.FINE, '== MEMORY STATS == Pdf.save with ' + streamSize + ' byte stream: Heap = ' + heapBeforeSave + ' / ' + heapLimit + ' bytes (' + percentUsed.setScale(2) + '% used)');

        // Create ContentVersion record using the stream
        Id contentVersionId = stream.saveToCV(filename);

        Integer heapSize = Limits.getHeapSize();
        heapLimit = Limits.getLimitHeapSize();
        percentUsed = (heapSize * 100.0) / heapLimit;
        System.debug(LoggingLevel.FINE, '== MEMORY STATS == Pdf.save final: Heap = ' + heapSize + ' / ' + heapLimit + ' bytes (' + percentUsed.setScale(2) + '% used)');
        return contentVersionId;
    }



    /**
     * Generates content streams for all pages
     * @return Map containing contentStreams, hasContent, and contentStreamObjects lists
     */
    private Map<String, List<Object>> generateContentStreams() {
        // Start object numbering after all pages
        contentStreamStart = 3 + currentPageNum;
        List<Integer> contentStreamObjects = new List<Integer>();

        // First determine which pages have content and prepare content streams
        List<String> contentStreams = new List<String>();
        List<Boolean> hasContent = new List<Boolean>();

        for (Integer i = 0; i < currentPageNum; i++) {
            // Get text and image elements for this page
            List<PdfText> pageText = i < pageTextElements.size() ? pageTextElements[i] : new List<PdfText>();
            List<PdfImage> pageImages = i < pageImageElements.size() ? pageImageElements[i] : new List<PdfImage>();

            // Debug text elements
            // System.debug('Page ' + (i+1) + ' has ' + (pageText != null ? pageText.size() : 0) + ' text elements');
            // if (pageText != null && !pageText.isEmpty()) {
            //     for (PdfText element : pageText) {
            //         System.debug('  Text element: "' + element.text + '" at (' + element.x + ',' + element.y + ')');
            //     }
            // }

            // Get rectangle elements for this page
            List<PdfRect> pageRects = i < pageRectElements.size() ? pageRectElements[i] : new List<PdfRect>();

            // Debug rectangle elements
            // if (pageRects != null && !pageRects.isEmpty()) {
            //     System.debug('Page ' + (i+1) + ' has ' + pageRects.size() + ' rectangle elements');
            //     for (PdfRect rect : pageRects) {
            //         System.debug('  Rectangle element: at (' + rect.x + ',' + rect.y + ') size ' + rect.width + 'x' + rect.height);
            //     }
            // }

            // Generate content stream if page has content (text, images, or rectangles)
            if ((pageText != null && !pageText.isEmpty()) ||
                (pageImages != null && !pageImages.isEmpty()) ||
                (pageRects != null && !pageRects.isEmpty())) {
                String content = writeContents(pageText, pageImages, i);
                contentStreams.add(content);
                hasContent.add(true);
            } else {
                contentStreams.add('');
                hasContent.add(false);
            }
        }

        Map<String, List<Object>> result = new Map<String, List<Object>>();
        result.put('contentStreams', contentStreams);
        result.put('hasContent', hasContent);
        result.put('contentStreamObjects', contentStreamObjects);
        return result;
    }

    /**
     * Creates and writes all page objects with content stream references
     * @param stream The current PDF stream
     * @param contentData Map containing contentStreams, hasContent, and contentStreamObjects lists
     * @param objectOffsets List to record object offsets
     * @return Updated stream with page objects added
     */
    private PdfStream createPageObjects(PdfStream stream, Map<String, List<Object>> contentData, List<Integer> objectOffsets) {
        List<Boolean> hasContent = (List<Boolean>)contentData.get('hasContent');
        List<Integer> contentStreamObjects = (List<Integer>)contentData.get('contentStreamObjects');

        for (Integer i = 0; i < currentPageNum; i++) {
            Integer pageObjNum = 3 + i;
            String pageObj = pageObjNum + ' 0 obj' + PdfConstants.LINE_BREAK
                           + PdfConstants.DICT_START
                           + PdfConstants.TYPE_PAGE + PdfConstants.LINE_BREAK
                           + '/Parent ' + PdfConstants.PAGES_OBJ_NUM + ' 0 R' + PdfConstants.LINE_BREAK
                           + '/MediaBox [0 0 ' + PdfConstants.PAGE_WIDTH + ' ' + PdfConstants.PAGE_HEIGHT + ']' + PdfConstants.LINE_BREAK;

            // Add content stream reference if this page has content
            if (hasContent[i]) {
                Integer contentObjNum = contentStreamStart + contentStreamObjects.size();
                contentStreamObjects.add(contentObjNum); // Store for later reference
                pageObj += '/Contents ' + contentObjNum + ' 0 R\r\n';
            }

            // Add page-specific resources if we have images for this page
            if (i < pageImageElements.size() && pageImageElements[i] != null && !pageImageElements[i].isEmpty()) {
                System.debug('Adding resources for page ' + (i+1) + ' with ' + pageImageElements[i].size() + ' images');
                pageObj += PdfConstants.PDF_STANDARD_RESOURCES
                        + '/XObject <<\r\n';

                for (PdfImage image : pageImageElements[i]) {
                    if (imageObjectNumbers.containsKey(image.imageId)) {
                        String imageId = image.imageId;
                        Integer objNum = imageObjectNumbers.get(imageId);
                        pageObj += '/' + imageId + ' ' + String.valueOf(objNum) + ' 0 R\r\n';
                        System.debug('Referenced image ' + imageId + ' with object number ' + objNum + ' in resources');
                    } else {
                        System.debug('WARNING: Image ' + image.imageId + ' has no assigned object number!');
                    }
                }

                pageObj += '>>\r\n'
                         + '>>\r\n';
            } else {
                // Add resources even when there are no images
                pageObj += '/Resources <<\r\n'
                        + '/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]\r\n' // Add ProcSet for all resource types
                        + '/Font <<\r\n'
                        + '/F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\r\n'
                        + '/F2 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\r\n'
                        + '/F3 << /Type /Font /Subtype /Type1 /BaseFont /Courier >>\r\n'
                        + '/F4 << /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>\r\n'
                        + '/F5 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >>\r\n'
                        + '/F6 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-BoldOblique >>\r\n'
                        + '/F7 << /Type /Font /Subtype /Type1 /BaseFont /Courier-Oblique >>\r\n'
                        + '/F8 << /Type /Font /Subtype /Type1 /BaseFont /Courier-BoldOblique >>\r\n'
                        + '>>\r\n'
                        + '>>\r\n';
            }

            pageObj += PdfConstants.DICT_END + PdfConstants.OBJ_END;
            stream.appendContent(pageObj, objectOffsets);
        }

        // Update the contentStreamObjects in the contentData map
        contentData.put('contentStreamObjects', contentStreamObjects);

        return stream;
    }

    /**
     * @description Converts a hexadecimal string to a decimal value
     * @param hex The hexadecimal string to convert
     * @return The decimal value
     */
    private Integer hexToDecimal(String hex) {
        String hexChars = '0123456789ABCDEF';
        hex = hex.toUpperCase();
        Integer val = 0;

        for (Integer i = 0; i < hex.length(); i++) {
            String chr = hex.substring(i, i+1);
            Integer idx = hexChars.indexOf(chr);
            if (idx == -1) {
                // Invalid hex character, default to 0
                System.debug(LoggingLevel.WARN, 'Invalid hex character: ' + chr);
                idx = 0;
            }
            val = (val * 16) + idx;
        }

        return val;
    }
}
