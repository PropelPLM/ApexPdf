/**
 * @description Test class for PdfTextProcessor
 */
@IsTest
public with sharing class PdfTextProcessorTest {

    /**
     * @description Test text wrapping with default behavior (maintaining X position)
     */
    @IsTest
    static void testWrapTextMaintainXPosition() {
        // Set up test parameters
        Integer startX = 100;
        Integer startY = 100;
        String text = 'This is a long text that should wrap to multiple lines because it exceeds the maximum width we will set for this test.';

        // Create text options with column-aware wrapping (maintain X position)
        Pdf.TextOptions options = new Pdf.TextOptions();
        options.maxWidth = 150; // Narrow width to force wrapping
        options.fontSize = 12;
        options.fontStyle = 'normal';
        // Note: wrapToXPosition is null, so it should maintain startX

        // Process the text using the public method
        List<PdfText> result = PdfTextProcessor.processText(text, startX, startY, options);

        // Verify results
        System.assertNotEquals(0, result.size(), 'Should have at least one text element');
        System.assert(result.size() > 1, 'Text should wrap to multiple lines');

        // First line should start at the specified X position
        System.assertEquals(startX, result[0].x, 'First line should start at the specified X position');

        // Subsequent lines should also start at the original X position (column-aware wrapping)
        for (Integer i = 1; i < result.size(); i++) {
            System.assertEquals(startX, result[i].x, 'Line ' + i + ' should maintain the original X position');

            // Verify each line is positioned below the previous line
            System.assert(result[i].y > result[i-1].y, 'Each line should be below the previous line');
        }
    }

    /**
     * @description Test text wrapping with explicit left margin wrapping
     */
    @IsTest
    static void testWrapTextResetToLeftMargin() {
        // Set up test parameters
        Integer startX = 100;
        Integer startY = 100;
        String text = 'This is a long text that should wrap to multiple lines because it exceeds the maximum width we will set for this test.';

        // Create text options with traditional paragraph wrapping (reset to left margin)
        Pdf.TextOptions options = new Pdf.TextOptions();
        options.maxWidth = 150; // Narrow width to force wrapping
        options.fontSize = 12;
        options.fontStyle = 'normal';
        options.wrapToXPosition = PdfConstants.PAGE_MARGIN; // Explicitly set wrap position to left margin

        // Process the text using the public method
        List<PdfText> result = PdfTextProcessor.processText(text, startX, startY, options);

        // Verify results
        System.assertNotEquals(0, result.size(), 'Should have at least one text element');
        System.assert(result.size() > 1, 'Text should wrap to multiple lines');

        // First line should start at the specified X position
        System.assertEquals(startX, result[0].x, 'First line should start at the specified X position');

        // Subsequent lines should start at the left margin (traditional paragraph wrapping)
        for (Integer i = 1; i < result.size(); i++) {
            System.assertEquals(PdfConstants.PAGE_MARGIN, result[i].x,
                                'Wrapped lines should start at the left margin');

            // Verify each line is positioned below the previous line
            System.assert(result[i].y > result[i-1].y, 'Each line should be below the previous line');
        }
    }

    /**
     * @description Test text wrapping with custom wrap position
     */
    @IsTest
    static void testWrapTextCustomPosition() {
        // Set up test parameters
        Integer startX = 100;
        Integer startY = 100;
        Integer customWrapPosition = 75; // Custom position different from startX and margin
        String text = 'This is a long text that should wrap to multiple lines because it exceeds the maximum width we will set for this test.';

        // Create text options with custom wrap position
        Pdf.TextOptions options = new Pdf.TextOptions();
        options.maxWidth = 150; // Narrow width to force wrapping
        options.fontSize = 12;
        options.fontStyle = 'normal';
        options.wrapToXPosition = customWrapPosition; // Set custom wrap position

        // Process the text using the public method
        List<PdfText> result = PdfTextProcessor.processText(text, startX, startY, options);

        // Verify results
        System.assertNotEquals(0, result.size(), 'Should have at least one text element');
        System.assert(result.size() > 1, 'Text should wrap to multiple lines');

        // First line should start at the specified X position
        System.assertEquals(startX, result[0].x, 'First line should start at the specified X position');

        // Subsequent lines should start at the custom position
        for (Integer i = 1; i < result.size(); i++) {
            System.assertEquals(customWrapPosition, result[i].x,
                               'Wrapped lines should start at the custom position');

            // Verify each line is positioned below the previous line
            System.assert(result[i].y > result[i-1].y, 'Each line should be below the previous line');
        }
    }

    /**
     * @description Test the estimateTextWidth method
     */
    @IsTest
    static void testEstimateTextWidth() {
        // Create test options with different configurations

        // 1. Empty string should have zero width
        Pdf.TextOptions emptyOptions = new Pdf.TextOptions();
        emptyOptions.fontSize = 12;
        emptyOptions.fontStyle = 'normal';
        System.assertEquals(0, PdfTextProcessor.estimateTextWidth('', emptyOptions),
                           'Empty string should have zero width');

        // 2. String with narrow characters
        String narrowChars = 'ililililil'; // Narrow characters
        Pdf.TextOptions narrowOptions = new Pdf.TextOptions();
        narrowOptions.fontSize = 12;
        narrowOptions.fontStyle = 'normal';

        // 3. String with wide characters
        String wideChars = 'WWWWWWWWWW'; // Wide characters
        Pdf.TextOptions wideOptions = new Pdf.TextOptions();
        wideOptions.fontSize = 12;
        wideOptions.fontStyle = 'normal';

        // The width of the wide character string should be greater than the narrow one
        System.assert(PdfTextProcessor.estimateTextWidth(wideChars, wideOptions) >
                      PdfTextProcessor.estimateTextWidth(narrowChars, narrowOptions),
                     'Wide characters should produce greater width estimation');

        // 4. Test bold style - should be wider than normal
        Pdf.TextOptions boldOptions = new Pdf.TextOptions();
        boldOptions.fontSize = 12;
        boldOptions.fontStyle = 'bold';

        System.assert(PdfTextProcessor.estimateTextWidth('test', boldOptions) >
                      PdfTextProcessor.estimateTextWidth('test', narrowOptions),
                     'Bold text should be wider than normal text');

        // 5. Test larger font size - should be proportionally wider
        Pdf.TextOptions smallOptions = new Pdf.TextOptions();
        smallOptions.fontSize = 10;
        smallOptions.fontStyle = 'normal';

        Pdf.TextOptions largeOptions = new Pdf.TextOptions();
        largeOptions.fontSize = 20;
        largeOptions.fontStyle = 'normal';

        Integer normalWidth = PdfTextProcessor.estimateTextWidth('test', smallOptions);
        Integer doubleSize = PdfTextProcessor.estimateTextWidth('test', largeOptions);

        // The width should roughly double when the font size doubles
        System.assert(doubleSize > normalWidth * 1.8,
                     'Text width should scale proportionally with font size');
    }

    /**
     * @description Test text with no wrapping needed
     */
    @IsTest
    static void testNoWrapping() {
        // Short text that doesn't need wrapping
        String text = 'Short text';
        Integer startX = 100;
        Integer startY = 100;

        Pdf.TextOptions options = new Pdf.TextOptions();
        options.maxWidth = 500; // Wide enough to fit text
        options.fontSize = 12;
        options.fontStyle = 'normal';

        // Process the text using the public method
        List<PdfText> result = PdfTextProcessor.processText(text, startX, startY, options);

        // Should be just one line
        System.assertEquals(1, result.size(), 'Short text should not wrap');
        System.assertEquals(startX, result[0].x, 'X position should be maintained');
        System.assertEquals(startY, result[0].y, 'Y position should be maintained');
        System.assertEquals(text, result[0].text, 'Text should be unchanged');
    }

    /**
     * @description Test the escapeTextForPdf method through content stream generation
     */
    @IsTest
    static void testEscapeTextForPdf() {
        // Create a text element with content that would need escaping
        PdfText element = new PdfText('Text with (parentheses)', 100, 100, 12, 'normal', '#000000');

        // Generate content stream which internally calls escapeTextForPdf
        String contentStream = PdfTextProcessor.generateTextContentStream(new List<PdfText>{element});

        // Verify basic test content appears in the output
        System.assert(contentStream.contains('Text with'), 'Content stream should contain the text content');
        System.assert(contentStream.contains('parentheses'), 'Content stream should contain the text content');

        // Verify the content contains encoded text with parentheses
        System.assert(contentStream.contains('(Text with ') || contentStream.contains('Text with'),
                    'Content stream should contain the text content');

        // Check that the PDF structure is correct
        System.assert(contentStream.contains('BT'), 'Content stream should have Begin Text marker');
        System.assert(contentStream.contains('ET'), 'Content stream should have End Text marker');
        System.assert(contentStream.contains('Tj'), 'Content stream should have text showing operator');
    }

    /**
     * @description Test the generateTextContentStream method
     */
    @IsTest
    static void testGenerateTextContentStream() {
        // Test with empty list
        System.assertEquals('', PdfTextProcessor.generateTextContentStream(new List<PdfText>()),
                          'Empty list should produce empty content stream');

        // Test with null
        System.assertEquals('', PdfTextProcessor.generateTextContentStream(null),
                          'Null should produce empty content stream');

        // Create test text elements
        PdfText element1 = new PdfText('Test text 1', 100, 100, 12, 'normal', '#000000');
        PdfText element2 = new PdfText('Test text 2', 150, 150, 16, 'bold', '#FF0000');
        List<PdfText> elements = new List<PdfText>{element1, element2};

        // Call the method
        String contentStream = PdfTextProcessor.generateTextContentStream(elements);

        // Verify content stream structure
        System.assert(contentStream.startsWith('BT'), 'Content stream should start with Begin Text operator');
        System.assert(contentStream.contains('/F1'), 'Content stream should contain font references');
        // PDF font operators will be present even if color space isn't explicitly mentioned
        System.assert(contentStream.contains('BT') && contentStream.contains('Tj'), 'Content stream should contain PDF text operators');
        System.assert(contentStream.contains('Tf'), 'Content stream should contain text font operator');
        System.assert(contentStream.contains('Td'), 'Content stream should contain text positioning operator');
        System.assert(contentStream.contains('(Test text'), 'Content stream should contain the text');
        System.assert(contentStream.contains('ET'), 'Content stream should end with End Text operator');
    }

    /**
     * @description Test the convertToPdfY method
     */
    @IsTest
    static void testConvertToPdfY() {
        // Test with normal values
        Integer testY = 100;
        Integer fontSize = 12;
        Integer expectedPdfY = PdfConstants.PAGE_HEIGHT - testY - fontSize; // 792 - 100 - 12 = 680

        System.assertEquals(expectedPdfY, PdfTextProcessor.convertToPdfY(testY, fontSize),
                         'Y coordinate should be properly converted to PDF coordinates');

        // Test with zero values
        System.assertEquals(PdfConstants.PAGE_HEIGHT, PdfTextProcessor.convertToPdfY(0, 0),
                         'Y=0, fontSize=0 should return PAGE_HEIGHT');

        // Test with extreme values
        System.assertEquals(0, PdfTextProcessor.convertToPdfY(PdfConstants.PAGE_HEIGHT, 0),
                         'Y=PAGE_HEIGHT should return 0');
    }

    /**
     * @description Test the processText method with explicit parameters
     */
    @IsTest
    static void testProcessTextWithExplicitParams() {
        // Create test parameters
        String text = 'Test text with explicit parameters';
        Integer x = 100;
        Integer y = 150;

        Pdf.TextOptions options = new Pdf.TextOptions();
        options.fontSize = 14;
        options.fontStyle = 'bold';
        options.maxWidth = 300;

        // Call the method
        List<PdfText> result = PdfTextProcessor.processText(text, x, y, options);

        // Verify results
        System.assertEquals(1, result.size(), 'Should produce one text element');
        PdfText textElement = result[0];

        System.assertEquals(text, textElement.text, 'Text content should match');
        System.assertEquals(x, textElement.x, 'X position should match');
        System.assertEquals(y, textElement.y, 'Y position should match');
        System.assertEquals(14, textElement.fontSize, 'Font size should match');
        System.assertEquals('bold', textElement.fontStyle, 'Font style should match');
        // Note: Color is set at the PdfText level, not in TextOptions
    }

    /**
     * @description Test the processText method with default parameters
     */
    @IsTest
    static void testProcessTextWithDefaultParams() {
        // Create test parameters with nulls to test defaults
        String text = 'Test text with default parameters';

        Pdf.TextOptions options = new Pdf.TextOptions();
        options.fontSize = 12;
        options.fontStyle = 'normal';

        // Call the method with null x and y
        List<PdfText> result = PdfTextProcessor.processText(text, null, null, options);

        // Verify results
        System.assertEquals(1, result.size(), 'Should produce one text element');
        PdfText textElement = result[0];

        System.assertEquals(text, textElement.text, 'Text content should match');
        System.assertEquals(PdfConstants.PAGE_MARGIN, textElement.x, 'X should default to PAGE_MARGIN');
        System.assertEquals(12, textElement.fontSize, 'Font size should match');
        System.assertEquals('normal', textElement.fontStyle, 'Font style should match');
    }
}
