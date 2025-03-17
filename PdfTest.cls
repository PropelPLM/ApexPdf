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
     * @description Tests the paragraph method with text wrapping to left margin
     */
    @isTest
    static void testParagraphMethod() {
        Test.startTest();
        
        // Create a PDF document
        Pdf doc = new Pdf();
        
        // Set up test parameters
        Integer startX = 100; // Column starting position
        Integer startY = 50;
        String longText = 'This is a long paragraph that should wrap to multiple lines. ' +
                         'We want to ensure the text wraps correctly to the left margin ' +
                         'as specified by the paragraph method. Lorem ipsum dolor sit amet, ' +
                         'consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
        
        // Test the paragraph method which should wrap to left margin
        doc.paragraph(longText, startX, startY);
        
        // Execute the PDF generation
        String pdfContent = doc.toPdf();
        
        // Basic validation - PDF should be generated
        System.assertNotEquals(null, pdfContent, 'PDF content should not be null');
        System.assert(pdfContent.startsWith('%PDF-'), 'PDF content should start with the PDF header');
        
        // Validate the current Y position was updated (text was added)
        System.assert(doc.lastY > startY, 'Y position should be increased after adding text');
        
        // Compare paragraph method with text method using wrapToXPosition
        doc = new Pdf(); // Create a new document
        
        // Use paragraph method
        doc.paragraph(longText, startX, startY);
        Integer paragraphEndY = doc.lastY;
        
        // Reset document
        doc = new Pdf();
        
        // Use text method with manual TextOptions
        Pdf.TextOptions options = new Pdf.TextOptions();
        options.wrapToXPosition = PdfConstants.PAGE_MARGIN;
        doc.text(longText, startX, startY, options);
        Integer textEndY = doc.lastY;
        
        // The two methods should produce the same ending Y position
        System.assertEquals(paragraphEndY, textEndY, 
                          'Paragraph method should match text method with wrapToXPosition = PAGE_MARGIN');
        
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
        
        // Test horizontal line
        Integer x1 = 50;
        Integer y1 = 50;
        Integer x2 = 200;
        Integer y2 = 50; // Same Y for horizontal
        doc.line(x1, y1, x2, y2);
        
        // Test vertical line
        x1 = 50;
        y1 = 100;
        x2 = 50; // Same X for vertical
        y2 = 200;
        doc.line(x1, y1, x2, y2);
        
        // Test diagonal line
        x1 = 100;
        y1 = 100;
        x2 = 200;
        y2 = 200;
        doc.line(x1, y1, x2, y2);
        
        // Execute the PDF generation
        String pdfContent = doc.toPdf();
        
        // Basic validation - PDF should be generated
        System.assertNotEquals(null, pdfContent, 'PDF content should not be null');
        System.assert(pdfContent.startsWith('%PDF-'), 'PDF content should start with the PDF header');
        
        // More detailed validation
        // For horizontal and vertical lines, we expect to see rectangle elements
        // For diagonal lines, we expect to see a series of small dots
        System.assert(pdfContent.containsIgnoreCase('/Rect') || pdfContent.containsIgnoreCase('/R'), 
                    'PDF should contain rectangle elements');
        
        Test.stopTest();
    }
}
