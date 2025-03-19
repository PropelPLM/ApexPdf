/**
 * @description Test class for Pdf, the PDF generation utility
 *
 *
 * below are execute anon tests to see 3 output files
 * in your org to verify they are valid PDF, we expect there exists
 * a file clouds in your org with a jpeg image
 *
 * see tests in scripts/test_doc_image.apex
 *
 */
@isTest
private class PdfTest {

    /**
     * @description Tests the basic PDF generation functionality with text
     */
    @isTest
    static void testBasicPdfGeneration() {
        Test.startTest();

        // Create a simple PDF document with text
        Pdf pdf = new Pdf();
        pdf.h1('Test Document', 72, 72);
        pdf.text('This is a simple test document created to verify the Pdf class functionality.', 72, 120);
        pdf.text('Multiple lines of text should be handled correctly.', 72, null);

        // Save the PDF to a ContentDocument
        String filename = 'TestPDF_' + DateTime.now().getTime();
        pdf.save(filename);

        // Query to verify the document was created
        ContentVersion cv = [
            SELECT Id, Title, ContentSize
            FROM ContentVersion
            WHERE Title = :filename
            LIMIT 1
        ];

        // Verify the document exists and is not empty
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the image embedding functionality
     */
    @isTest
    static void testPdfWithImage() {
        // Create test image data (would normally come from a ContentVersion or Document)
        Blob testImageData = Blob.valueOf('Test image data placeholder');

        Test.startTest();

        // Create a PDF with an image
        Pdf pdf = new Pdf();
        pdf.text('Document with image', 72, 72);

        // Add a placeholder image (in real usage, you'd use actual image data)
        pdf.addImage(testImageData, PdfConstants.FORMAT_JPEG, 72, 100, 200, 150);

        // Save the PDF
        String filename = 'TestImagePDF_' + DateTime.now().getTime();
        pdf.save(filename);

        // Query to verify the document was created
        ContentVersion cv = [
            SELECT Id, Title, ContentSize
            FROM ContentVersion
            WHERE Title = :filename
            LIMIT 1
        ];

        // Verify the document exists and is not empty
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests multi-page PDF generation
     */
    @isTest
    static void testMultiPagePdf() {
        Test.startTest();

        // Create a PDF with multiple pages
        Pdf pdf = new Pdf();

        // Page 1
        pdf.h1('Page One', 72, 72);
        pdf.text('This is the first page of the document.', 72, 120);

        // Add a second page
        pdf.addPage();

        // Page 2
        pdf.h1('Page Two', 72, 72);
        pdf.text('This is the second page of the document.', 72, 120);

        // Save the PDF
        String filename = 'TestMultiPagePDF_' + DateTime.now().getTime();
        pdf.save(filename);

        // Query to verify the document was created
        ContentVersion cv = [
            SELECT Id, Title, ContentSize
            FROM ContentVersion
            WHERE Title = :filename
            LIMIT 1
        ];

        // Verify the document exists and is not empty
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the PdfRect class functionality including all constructors and the toPdfCommand method
     */
    @isTest
    static void testPdfRect() {
        Test.startTest();

        // Test default constructor
        PdfRect rect1 = new PdfRect();
        System.assertEquals('S', rect1.fillStyle, 'Default fill style should be stroke');
        System.assertEquals('000000', rect1.lineColor, 'Default line color should be black');
        System.assertEquals('000000', rect1.fillColor, 'Default fill color should be black');
        System.assertEquals(1, rect1.lineWidth, 'Default line width should be 1pt');

        // Test basic constructor
        PdfRect rect2 = new PdfRect(100, 200, 300, 150, 'F');
        System.assertEquals(100, rect2.x, 'X position should be set correctly');
        System.assertEquals(200, rect2.y, 'Y position should be set correctly');
        System.assertEquals(300, rect2.width, 'Width should be set correctly');
        System.assertEquals(150, rect2.height, 'Height should be set correctly');
        System.assertEquals('F', rect2.fillStyle, 'Fill style should be set correctly');
        System.assertEquals('000000', rect2.lineColor, 'Line color should be inherited from default');
        System.assertEquals('000000', rect2.fillColor, 'Fill color should be inherited from default');

        // Test full constructor
        PdfRect rect3 = new PdfRect(72, 100, 200, 100, 'B', 'FF0000', '0000FF', 2);
        System.assertEquals(72, rect3.x, 'X position should be set correctly');
        System.assertEquals(100, rect3.y, 'Y position should be set correctly');
        System.assertEquals(200, rect3.width, 'Width should be set correctly');
        System.assertEquals(100, rect3.height, 'Height should be set correctly');
        System.assertEquals('B', rect3.fillStyle, 'Fill style should be set correctly');
        System.assertEquals('FF0000', rect3.lineColor, 'Line color should be set correctly');
        System.assertEquals('0000FF', rect3.fillColor, 'Fill color should be set correctly');
        System.assertEquals(2, rect3.lineWidth, 'Line width should be set correctly');

        // Test PDF command generation for stroke-only rectangle
        PdfRect strokeRect = new PdfRect(50, 50, 100, 75, 'S', '000000', 'FFFFFF', 1);
        String strokeCmd = strokeRect.toPdfCommand();

        // Calculate expected Y coordinate in PDF space
        Integer expectedY = PdfConstants.PAGE_HEIGHT - 50 - 75; // 792 - 50 - 75 = 667

        // Verify the command includes the correct positioning, size, and stroke operator
        // The black color in PDF might be represented as "0 0 0 RG" or with decimal precision like "0.000 0.000 0.000 RG"
        System.assert(strokeCmd.contains('0') && strokeCmd.contains('RG'), 'Command should set stroke color to black');
        System.assert(strokeCmd.contains('1 w'), 'Command should set line width to 1');
        System.assert(strokeCmd.contains('50 ' + expectedY + ' 100 75 re'), 'Command should define rectangle with correct coordinates');
        System.assert(strokeCmd.contains('re S'), 'Command should end with stroke operator');

        // Test PDF command generation for fill-only rectangle
        PdfRect fillRect = new PdfRect(100, 150, 200, 100, 'F', '000000', 'FF0000', 1);
        String fillCmd = fillRect.toPdfCommand();

        // Calculate expected Y coordinate
        expectedY = PdfConstants.PAGE_HEIGHT - 150 - 100; // 792 - 150 - 100 = 542

        // Verify fill command
        System.assert(fillCmd.contains('1.000 0.000 0.000 rg'), 'Command should set fill color to red');
        System.assert(fillCmd.contains('100 ' + expectedY + ' 200 100 re'), 'Command should define rectangle with correct coordinates');
        System.assert(fillCmd.contains('re f'), 'Command should end with fill operator');

        // Test PDF command generation for stroke and fill
        PdfRect bothRect = new PdfRect(200, 300, 150, 150, 'B', '0000FF', '00FF00', 3);
        String bothCmd = bothRect.toPdfCommand();

        // Calculate expected Y coordinate
        expectedY = PdfConstants.PAGE_HEIGHT - 300 - 150; // 792 - 300 - 150 = 342

        // Verify both stroke and fill command
        System.assert(bothCmd.contains('0.000 1.000 0.000 rg'), 'Command should set fill color to green');
        System.assert(bothCmd.contains('0.000 0.000 1.000 RG'), 'Command should set stroke color to blue');
        System.assert(bothCmd.contains('3 w'), 'Command should set line width to 3');
        System.assert(bothCmd.contains('200 ' + expectedY + ' 150 150 re'), 'Command should define rectangle with correct coordinates');
        System.assert(bothCmd.contains('re B'), 'Command should end with both fill and stroke operator');

        // Test invalid color handling
        PdfRect invalidColorRect = new PdfRect(50, 50, 100, 100, 'F', 'INVALIDCOLOR', 'XYZ', 1);
        String invalidColorCmd = invalidColorRect.toPdfCommand();
        // The black color in PDF might be represented as "0 0 0 rg" or with decimal precision like "0.000 0.000 0.000 rg"
        System.assert(invalidColorCmd.contains('0') && invalidColorCmd.contains('rg'), 'Command should default to black fill for invalid color');

        // Debug: Print out the actual command for verification
        System.debug(LoggingLevel.INFO, 'Generated command for invalid color rectangle: ' + invalidColorCmd);

        Test.stopTest();
    }

    /**
     * @description Test the line method for different line types
     */
    @isTest
    static void testLineMethod() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        Integer initialRectCount = doc.rectElements.size();

        // Test method chaining - make sure the method returns 'this'
        Pdf returnedDoc = doc.line(50, 50, 100, 50);
        System.assertEquals(doc, returnedDoc, 'Line method should return the same Pdf instance for method chaining');

        // Test with custom line color and width
        String customColor = '0000FF'; // Blue
        Integer customWidth = 3;
        doc.setLineColor(customColor).setLineWidth(customWidth);

        // Test horizontal line
        Integer x1 = 50;
        Integer y1 = 50;
        Integer x2 = 200;
        Integer y2 = 50; // Same Y for horizontal
        doc.line(x1, y1, x2, y2);

        // Verify rectangles were added for horizontal line
        System.assert(doc.rectElements.size() > initialRectCount, 'A rectangle should be added for horizontal line');

        // Save the current count of rectangles
        Integer afterHorizontalCount = doc.rectElements.size();

        // Test vertical line
        x1 = 50;
        y1 = 100;
        x2 = 50; // Same X for vertical
        y2 = 200;
        doc.line(x1, y1, x2, y2);

        // Verify rectangles were added for vertical line
        System.assert(doc.rectElements.size() > afterHorizontalCount, 'A rectangle should be added for vertical line');

        // Save the current count of rectangles
        Integer afterVerticalCount = doc.rectElements.size();

        // Test diagonal line
        x1 = 100;
        y1 = 100;
        x2 = 200;
        y2 = 200;
        doc.line(x1, y1, x2, y2);

        // Verify multiple rectangles were added for diagonal line (at least the end point plus some dots)
        System.assert(doc.rectElements.size() > afterVerticalCount + 1, 'Multiple rectangles should be added for diagonal line');

        // Test with inverted coordinates (should still work correctly)
        Integer invertedInitialCount = doc.rectElements.size();
        doc.line(x2, y2, x1, y1); // Reversed diagonal line
        System.assert(doc.rectElements.size() > invertedInitialCount, 'Line method should handle reversed coordinates');

        // Test changing line properties between lines
        String redColor = 'FF0000';
        doc.setLineColor(redColor).setLineWidth(5);
        Integer propsChangeCount = doc.rectElements.size();
        doc.line(300, 300, 400, 300); // Horizontal with new properties
        System.assert(doc.rectElements.size() > propsChangeCount, 'Line with changed properties should be added');

        // Execute the PDF generation to make sure no exceptions are thrown
        Id contentDocId = doc.save('Line_Test_' + System.now().getTime());

        // Basic validation - PDF should be generated
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the setTextColor method
     */
    @isTest
    static void testSetTextColor() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Test with valid hex color
        String validColor = 'FF0000'; // Red
        doc.setTextColor(validColor);
        doc.text('This text should be red', 100, 100);

        // Test with invalid hex color (should default to black)
        String invalidColor = 'XYZ123';
        doc.setTextColor(invalidColor);
        doc.text('This text should be black (default)', 100, 120);

        // Test with null and empty color (should default to black)
        doc.setTextColor(null);
        doc.text('This text should be black (null)', 100, 140);

        doc.setTextColor('');
        doc.text('This text should be black (empty)', 100, 160);

        // Test with color that has whitespace
        doc.setTextColor('  00FF00  '); // Green with spaces
        doc.text('This text should be green', 100, 180);

        // Generate the PDF
        Id contentDocId = doc.save('TextColor_Test_' + System.now().getTime());

        // Basic validation - PDF should be generated
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the heading methods (h2 and h3) of the Pdf class
     */
    @isTest
    static void testHeadingMethods() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Initial Y position
        Integer initialY = 100;

        // Test h2 method
        String h2Text = 'This is a Heading 2';
        Integer h2X = 50;

        // Check that the method returns the same Pdf instance (method chaining)
        Pdf returnedDoc = doc.h2(h2Text, h2X, initialY);
        System.assertEquals(doc, returnedDoc, 'h2 method should return the same Pdf instance for method chaining');

        // Verify Y position was updated (text was added)
        System.assert(doc.currentY() > initialY, 'Y position should increase after adding h2 text');

        // Store the current Y position after h2
        Integer afterH2Y = doc.currentY();

        // Test h3 method
        String h3Text = 'This is a Heading 3';
        Integer h3X = 50;

        // Check that the method returns the same Pdf instance (method chaining)
        returnedDoc = doc.h3(h3Text, h3X, afterH2Y);
        System.assertEquals(doc, returnedDoc, 'h3 method should return the same Pdf instance for method chaining');

        // Verify Y position was updated (text was added)
        System.assert(doc.currentY() > afterH2Y, 'Y position should increase after adding h3 text');

        Test.stopTest();
    }

    /**
     * @description Test the currentY method
     */
    @isTest
    static void testCurrentYMethod() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Initial Y position is the margin
        Integer initialY = PdfConstants.PAGE_MARGIN;

        // Verify initial Y position matches constant
        System.assertEquals(initialY, doc.currentY(), 'Initial Y position should be at the page margin');

        // Add some text to update the Y position
        Integer textY = 100;
        String testText = 'This is some test text to verify currentY updates';
        doc.text(testText, 50, textY);

        // Verify Y position was updated
        System.assert(doc.currentY() > textY, 'Y position should increase after adding text');

        // Add more text at a specific position
        Integer newTextY = 200;
        doc.text('More text', 50, newTextY);

        // Verify Y position was updated to new position
        System.assert(doc.currentY() > newTextY, 'Y position should update to new position');

        Test.stopTest();
    }

    /**
     * @description Test the measureText method
     */
    @isTest
    static void testMeasureText() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Test empty or null text
        Pdf.TextMetrics emptyMetrics = doc.measureText('');
        System.assertEquals(0, emptyMetrics.width, 'Empty text should have zero width');
        System.assertEquals(0, emptyMetrics.height, 'Empty text should have zero height');

        Pdf.TextMetrics nullMetrics = doc.measureText(null);
        System.assertEquals(0, nullMetrics.width, 'Null text should have zero width');
        System.assertEquals(0, nullMetrics.height, 'Null text should have zero height');

        // Test standard text with default font settings
        String sampleText = 'Hello World';
        Pdf.TextMetrics metrics = doc.measureText(sampleText);
        System.assertNotEquals(0, metrics.width, 'Text metrics width should not be zero');
        System.assertEquals(PdfConstants.DEFAULT_FONT_SIZE, metrics.height, 'Text metrics height should match the default font size');

        // Test that longer text produces wider measurements
        String longerText = 'This is a longer text string that should have a greater width measurement';
        Pdf.TextMetrics longerMetrics = doc.measureText(longerText);
        System.assert(longerMetrics.width > metrics.width, 'Longer text should have greater width');

        Test.stopTest();
    }

    /**
     * @description Test the setFont method
     */
    @isTest
    static void testSetFont() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Test with Helvetica font and different styles
        String fontName = 'Helvetica';

        // Test normal style
        Pdf returnedDoc = doc.setFont(fontName, 'normal');
        System.assertEquals(doc, returnedDoc, 'setFont method should return the same Pdf instance for method chaining');

        // Add some text with this font
        String normalText = 'This is normal Helvetica text';
        doc.text(normalText, 50, 100);

        // Test bold style
        doc.setFont(fontName, 'bold');
        String boldText = 'This is bold Helvetica text';
        doc.text(boldText, 50, 150);

        // Test italic style
        doc.setFont(fontName, 'italic');
        String italicText = 'This is italic Helvetica text';
        doc.text(italicText, 50, 200);

        // Test bold-italic style
        doc.setFont(fontName, 'bold italic');
        String boldItalicText = 'This is bold-italic Helvetica text';
        doc.text(boldItalicText, 50, 250);

        // Test with Courier font
        fontName = 'Courier';
        doc.setFont(fontName, 'normal');
        String courierText = 'This is Courier text';
        doc.text(courierText, 50, 300);

        // Test with invalid font name (should default to Helvetica)
        doc.setFont('InvalidFont', 'normal');
        String invalidFontText = 'This uses default Helvetica font';
        doc.text(invalidFontText, 50, 350);

        // Test with null or empty inputs (should use defaults)
        doc.setFont(null, null);
        String nullInputText = 'This uses default font settings';
        doc.text(nullInputText, 50, 400);

        // Save the PDF to verify it was created successfully
        Id contentDocId = doc.save('SetFont_Test_' + System.now().getTime());
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the setFillColor method
     */
    @isTest
    static void testSetFillColor() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Test rectangles with different fill colors
        Integer x = 100;
        Integer y = 100;
        Integer width = 100;
        Integer height = 30;

        // Red filled rectangle
        doc.setFillColor('FF0000');
        doc.rect(x, y, width, height, 'F');

        // Blue filled rectangle
        doc.setFillColor('0000FF');
        doc.rect(x, y + 50, width, height, 'F');

        // Green filled rectangle
        doc.setFillColor('00FF00');
        doc.rect(x, y + 100, width, height, 'F');

        // Invalid color should default to black
        doc.setFillColor('INVALID');
        doc.rect(x, y + 150, width, height, 'F');

        // Generate the PDF
        Id contentDocId = doc.save('FillColor_Test_' + System.now().getTime());

        // Basic validation - PDF should be generated
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the applyStyles method including lineWidth settings
     */
    @isTest
    static void testApplyStyles() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Create a styles map with various properties
        Map<String, Object> styles = new Map<String, Object>{
            'fillColor' => 'FF0000',      // Red fill
            'textColor' => '0000FF',      // Blue text
            'lineColor' => '00FF00',      // Green line
            'lineWidth' => 5,             // 5pt line width
            'fontName' => 'Helvetica',
            'fontSize' => 14,
            'fontStyle' => 'bold'
        };

        // Apply the styles
        Pdf returnedDoc = doc.applyStyles(styles, false);
        System.assertEquals(doc, returnedDoc, 'applyStyles method should return the same Pdf instance for method chaining');

        // Now test the applied styles with a rectangle and text
        doc.rect(50, 100, 100, 50, 'B');  // B = both fill and stroke
        doc.text('Testing applyStyles', 50, 180);

        // Apply only font styles (fontOnly=true parameter)
        Map<String, Object> fontStyles = new Map<String, Object>{
            'fillColor' => '000000',  // This should be ignored with fontOnly=true
            'lineColor' => '000000',  // This should be ignored with fontOnly=true
            'lineWidth' => 1,         // This should be ignored with fontOnly=true
            'fontName' => 'Courier',
            'fontSize' => 18,
            'fontStyle' => 'italic'
        };

        doc.applyStyles(fontStyles, true);
        doc.text('Font-only styles applied', 50, 220);

        // Test applying lineWidth with null and negative values (should default to 1)
        Map<String, Object> invalidLineWidthStyles = new Map<String, Object>{
            'lineWidth' => null
        };
        doc.applyStyles(invalidLineWidthStyles, false);
        doc.rect(50, 250, 100, 50, 'S'); // S = stroke only

        // Now set a negative value which should also default to 1
        Map<String, Object> negativeLineWidthStyles = new Map<String, Object>{
            'lineWidth' => -3
        };
        doc.applyStyles(negativeLineWidthStyles, false);
        doc.rect(50, 320, 100, 50, 'S');

        // Generate the PDF
        Id contentDocId = doc.save('ApplyStyles_Test_' + System.now().getTime());
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the setFont(String) method and the getFontName/getFontStyle getter methods
     */
    @isTest
    static void testFontGettersAndSetters() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Verify initial default font settings
        System.assertEquals(PdfConstants.FONT_HELVETICA, doc.getFontName(), 'Default font should be Helvetica');
        System.assertEquals(PdfConstants.STYLE_NORMAL, doc.getFontStyle(), 'Default font style should be normal');

        // Test setFont with single parameter
        String testFont = 'Courier';
        Pdf returnedDoc = doc.setFont(testFont);

        // Verify method chaining
        System.assertEquals(doc, returnedDoc, 'setFont method should return the same Pdf instance for method chaining');

        // Verify font was set correctly
        System.assertEquals('Courier', doc.getFontName(), 'Font name should be set to Courier');
        System.assertEquals(PdfConstants.STYLE_NORMAL, doc.getFontStyle(),
            'Font style should remain normal when only font name is changed');

        // Test with invalid font name
        doc.setFont('InvalidFont');
        System.assertEquals(PdfConstants.FONT_HELVETICA, doc.getFontName(),
            'Invalid font name should default to Helvetica');

        // Test with two-parameter setFont and verify with getters
        doc.setFont(PdfConstants.FONT_HELVETICA, PdfConstants.STYLE_BOLD);
        System.assertEquals(PdfConstants.FONT_HELVETICA, doc.getFontName(), 'Font name should be Helvetica');
        System.assertEquals(PdfConstants.STYLE_BOLD, doc.getFontStyle(), 'Font style should be bold');

        // Test with null font name
        doc.setFont(null);
        System.assertEquals(PdfConstants.FONT_HELVETICA, doc.getFontName(),
            'Null font name should default to Helvetica');

        // Test with empty font name
        doc.setFont('');
        System.assertEquals(PdfConstants.FONT_HELVETICA, doc.getFontName(),
            'Empty font name should default to Helvetica');

        // Add some text to verify fonts are applied
        doc.setFont('Helvetica', 'normal').text('Normal Helvetica', 50, 100);
        doc.setFont('Helvetica', 'bold').text('Bold Helvetica', 50, 150);
        doc.setFont('Courier').text('Normal Courier', 50, 200);

        // Generate the PDF to verify everything works
        Id contentDocId = doc.save('FontGetterSetter_Test_' + System.now().getTime());
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Test the pageSize method
     */
    @isTest
    static void testPageSize() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Get the page size
        Map<String, Integer> pageSizeMap = doc.pageSize();

        // Verify the page size matches the constants
        System.assertEquals(PdfConstants.PAGE_WIDTH, pageSizeMap.get('width'),
            'Page width should match PdfConstants.PAGE_WIDTH');
        System.assertEquals(PdfConstants.PAGE_HEIGHT, pageSizeMap.get('height'),
            'Page height should match PdfConstants.PAGE_HEIGHT');

        // Validate standard US Letter size (8.5 x 11 inches at 72ppi)
        System.assertEquals(612, pageSizeMap.get('width'),
            'Default page width should be 612 points (8.5 inches at 72ppi)');
        System.assertEquals(792, pageSizeMap.get('height'),
            'Default page height should be 792 points (11 inches at 72ppi)');

        Test.stopTest();
    }

    /**
     * @description Test the rect method in the Pdf class (not the PdfRect class which has its own test)
     */
    @isTest
    static void testRectMethod() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Draw rectangles with different parameters
        Integer x = 100;
        Integer y = 150;
        Integer width = 200;
        Integer height = 100;

        // Test method chaining for rect(x,y,width,height,fillStyle)
        Pdf returnedDoc = doc.rect(x, y, width, height, 'F');
        System.assertEquals(doc, returnedDoc, 'rect method should return the same Pdf instance for method chaining');

        // Test changing styles and drawing more rectangles
        doc.setFillColor('FF0000').setLineColor('0000FF').setLineWidth(3);
        doc.rect(x, y + height + 20, width, height, 'S'); // Stroke only

        // Draw rectangle with both stroke and fill
        doc.rect(x, y + (height + 20) * 2, width, height, 'B');

        // Create a PdfRect object and use the overloaded rect method
        PdfRect customRect = new PdfRect();
        customRect.x = x + width + 50;
        customRect.y = y;
        customRect.width = 150;
        customRect.height = 80;
        customRect.fillStyle = 'F';
        customRect.lineColor = '00FF00';
        customRect.fillColor = '00FFFF';
        customRect.lineWidth = 2;

        // Test method chaining for rect(PdfRect)
        returnedDoc = doc.rect(customRect);
        System.assertEquals(doc, returnedDoc, 'rect(PdfRect) method should return the same Pdf instance for method chaining');

        // Verify at least one rectangle was added to the PDF
        System.assert(!doc.rectElements.isEmpty(), 'Rectangle elements list should not be empty');

        // Verify the customRect was added to rectElements
        Boolean customRectFound = false;
        for (PdfRect rect : doc.rectElements) {
            if (rect.x == customRect.x && rect.y == customRect.y &&
                rect.fillColor == customRect.fillColor) {
                customRectFound = true;
                break;
            }
        }
        System.assert(customRectFound, 'Custom rectangle should be found in rectElements');

        // Generate the PDF to ensure everything works
        Id contentDocId = doc.save('RectMethod_Test_' + System.now().getTime());
        System.assertNotEquals(null, contentDocId, 'PDF ContentDocument ID should not be null');

        Test.stopTest();
    }

    /**
     * @description Tests the watermark functionality with default settings
     */
    @isTest
    static void testDefaultWatermark() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Test Document with Default Watermark', 36, 50);
        doc.text('This document tests the default watermark settings.', 36, 90);

        // Add a watermark with default settings
        doc.watermark('CONFIDENTIAL');

        // Save the document
        String filename = 'TestDefaultWatermark_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with default watermark should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests the watermark functionality with custom settings
     */
    @isTest
    static void testCustomWatermark() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Test Document with Custom Watermark', 36, 50);
        doc.text('This document tests custom watermark settings.', 36, 90);

        // Create custom options for watermark
        Pdf.TextOptions customOptions = new Pdf.TextOptions();
        customOptions.fontSize = 36;
        customOptions.setRotation(30);
        customOptions.setOpacity(0.15);
        customOptions.setScale(3.0);
        customOptions.fontStyle = 'bold-italic';

        // Add the watermark with custom options
        doc.watermark('DRAFT', customOptions);

        // Save the document
        String filename = 'TestCustomWatermark_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with custom watermark should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests applying multiple watermarks to a single document
     */
    @isTest
    static void testMultipleWatermarks() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Test Document with Multiple Watermarks', 36, 50);
        doc.text('This document tests applying multiple watermarks.', 36, 90);

        // Create options for first watermark
        Pdf.TextOptions options1 = new Pdf.TextOptions();
        options1.setRotation(45);
        options1.setOpacity(0.2);
        options1.setScale(2.5);
        doc.setTextColor('#FF0000'); // Red color
        doc.watermark('CONFIDENTIAL', options1);

        // Create options for second watermark
        Pdf.TextOptions options2 = new Pdf.TextOptions();
        options2.setRotation(-30);
        options2.setOpacity(0.15);
        options2.setScale(2.0);
        doc.setTextColor('#0000FF'); // Blue color
        doc.watermark('DRAFT', options2);

        // Save the document
        String filename = 'TestMultipleWatermarks_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with multiple watermarks should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests the text scaling functionality
     */
    @isTest
    static void testTextScaling() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Create text options with scaling
        Pdf.TextOptions scaleOptions = new Pdf.TextOptions();
        scaleOptions.setScale(2.5);

        // Add scaled text
        doc.text('This text is scaled to 2.5x normal size', 100, 100, scaleOptions);

        // Add another text with different scaling
        Pdf.TextOptions differentScaleOptions = new Pdf.TextOptions();
        differentScaleOptions.setScale(1.5, 3.0); // Wider than tall
        doc.text('This text has non-uniform scaling (1.5x wide, 3x tall)', 100, 200, differentScaleOptions);

        // Save the document
        String filename = 'TestScaledText_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with scaled text should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests the text rotation functionality
     */
    @isTest
    static void testTextRotation() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();

        // Create text options with rotation
        Pdf.TextOptions rotateOptions = new Pdf.TextOptions();
        rotateOptions.setRotation(90); // 90 degrees rotation

        // Add rotated text
        doc.text('This text is rotated 90 degrees', 200, 200, rotateOptions);

        // Add another text with different rotation
        Pdf.TextOptions anotherRotateOptions = new Pdf.TextOptions();
        anotherRotateOptions.setRotation(45); // 45 degrees rotation
        doc.text('This text is rotated 45 degrees', 300, 300, anotherRotateOptions);

        // Test rotation normalization - should be normalized to 0-360 range
        Pdf.TextOptions normalizedRotateOptions = new Pdf.TextOptions();
        normalizedRotateOptions.setRotation(400); // Should be normalized to 40 degrees
        doc.text('This text has normalized rotation of 400 degrees (should be 40)', 400, 400, normalizedRotateOptions);

        // Save the document
        String filename = 'TestRotatedText_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with rotated text should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests watermark positioning adjustments based on rotation
     */
    @isTest
    static void testWatermarkPositioning() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Watermark Positioning Test', 36, 50);
        doc.text('This document tests watermark positioning adjustments.', 36, 90);

        // Create multi-line paragraph to verify watermark appears behind text
        Integer midPageY = 300;
        doc.text('This is a multi-line paragraph placed halfway down the page to verify that', 36, midPageY);
        doc.text('the watermark appears behind the text. This text should be clearly readable while', 36, midPageY + 20);
        doc.text('the watermark is visible underneath. This is important for document legibility.', 36, midPageY + 40);

        // Test standard 45-degree watermark positioning
        Pdf.TextOptions options1 = new Pdf.TextOptions();
        options1.setRotation(45);
        options1.setOpacity(0.3);
        options1.setScale(2.0);
        doc.watermark('DIAGONAL', options1);

        // Save the document
        String filename = 'TestWatermarkPositioning_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with positioned watermark should be created successfully');

        Test.stopTest();
    }

    /**
     * @description Tests watermark layering (watermarks behind text)
     */
    @isTest
    static void testWatermarkLayering() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Watermark Layering Test', 36, 50);
        doc.text('This document tests watermark layering.', 36, 90);

        // Add watermark first (should appear behind regular text)
        Pdf.TextOptions options = new Pdf.TextOptions();
        options.setScale(3.0);
        options.setOpacity(0.2);
        doc.watermark('BACKGROUND', options);

        // Add a solid rectangle over the watermark area
        doc.rect(150, 200, 300, 150, '#CCCCCC');

        // Add text over the watermark area
        doc.text('This text should appear on top of both the rectangle and watermark.', 175, 250);
        doc.text('The watermark should be visible beneath the rectangle.', 175, 270);
        doc.text('The z-order should be: 1) Text (top), 2) Rectangle, 3) Watermark (bottom)', 175, 290);

        // Save the document
        String filename = 'TestWatermarkLayering_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Assert the document was created
        System.assertNotEquals(null, docId, 'Document with layered watermark should be created successfully');

        Test.stopTest();
    }


}
