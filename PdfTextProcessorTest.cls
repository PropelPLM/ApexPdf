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
}
