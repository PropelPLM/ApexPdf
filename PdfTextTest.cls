/**
 * @description Test class for PdfText
 */
@IsTest
public with sharing class PdfTextTest {

    /**
     * @description Test the default constructor for PdfText
     */
    @IsTest
    static void testDefaultConstructor() {
        // Create a PdfText with default constructor
        String text = 'Test Text';
        Integer x = 100;
        Integer y = 200;
        Integer fontSize = 12;
        String fontStyle = 'normal';

        PdfText pdfText = new PdfText(text, x, y, fontSize, fontStyle);

        // Verify all properties
        System.assertEquals(text, pdfText.text, 'Text should match');
        System.assertEquals(x, pdfText.x, 'X coordinate should match');
        System.assertEquals(y, pdfText.y, 'Y coordinate should match');
        System.assertEquals(fontSize, pdfText.fontSize, 'Font size should match');
        System.assertEquals(fontStyle, pdfText.fontStyle, 'Font style should match');
        System.assertEquals('000000', pdfText.textColor, 'Default text color should be black');
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText.fontName, 'Default font should be Helvetica');
        System.assertEquals(false, pdfText.needsPageBreak, 'Page break should be false by default');
    }

    /**
     * @description Test constructor with custom text color
     */
    @IsTest
    static void testConstructorWithColor() {
        // Create a PdfText with custom color
        String text = 'Test Text';
        Integer x = 100;
        Integer y = 200;
        Integer fontSize = 12;
        String fontStyle = 'normal';
        String textColor = 'FF0000'; // Red

        PdfText pdfText = new PdfText(text, x, y, fontSize, fontStyle, textColor);

        // Verify all properties
        System.assertEquals(text, pdfText.text, 'Text should match');
        System.assertEquals(x, pdfText.x, 'X coordinate should match');
        System.assertEquals(y, pdfText.y, 'Y coordinate should match');
        System.assertEquals(fontSize, pdfText.fontSize, 'Font size should match');
        System.assertEquals(fontStyle, pdfText.fontStyle, 'Font style should match');
        System.assertEquals(textColor, pdfText.textColor, 'Text color should match');
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText.fontName, 'Default font should be Helvetica');
    }

    /**
     * @description Test constructor with custom text color and font
     */
    @IsTest
    static void testConstructorWithColorAndFont() {
        // Create a PdfText with custom color and font
        String text = 'Test Text';
        Integer x = 100;
        Integer y = 200;
        Integer fontSize = 12;
        String fontStyle = 'normal';
        String textColor = '0000FF'; // Blue
        String fontName = PdfConstants.FONT_HELVETICA_BOLD;

        PdfText pdfText = new PdfText(text, x, y, fontSize, fontStyle, textColor, fontName);

        // Verify all properties
        System.assertEquals(text, pdfText.text, 'Text should match');
        System.assertEquals(x, pdfText.x, 'X coordinate should match');
        System.assertEquals(y, pdfText.y, 'Y coordinate should match');
        System.assertEquals(fontSize, pdfText.fontSize, 'Font size should match');
        System.assertEquals(fontStyle, pdfText.fontStyle, 'Font style should match');
        System.assertEquals(textColor, pdfText.textColor, 'Text color should match');
        System.assertEquals(fontName, pdfText.fontName, 'Font name should match');
    }

    /**
     * @description Test invalid color format handling
     */
    @IsTest
    static void testInvalidColorFormat() {
        // Test with invalid color format (non-alphanumeric characters)
        PdfText pdfText1 = new PdfText('Test', 100, 200, 12, 'normal', 'FF00!@');
        System.assertEquals('000000', pdfText1.textColor, 'Invalid color with special characters should default to black');

        // Test with invalid color format (wrong length)
        PdfText pdfText2 = new PdfText('Test', 100, 200, 12, 'normal', 'FF00');
        System.assertEquals('000000', pdfText2.textColor, 'Invalid color length should default to black');

        // Test with null color
        PdfText pdfText3 = new PdfText('Test', 100, 200, 12, 'normal', null);
        System.assertEquals('000000', pdfText3.textColor, 'Null color should default to black');

        // Test with empty color
        PdfText pdfText4 = new PdfText('Test', 100, 200, 12, 'normal', '');
        System.assertEquals('000000', pdfText4.textColor, 'Empty color should default to black');

        // Test with spaces
        PdfText pdfText5 = new PdfText('Test', 100, 200, 12, 'normal', '  FF0000  ');
        System.assertEquals('FF0000', pdfText5.textColor, 'Color with spaces should be trimmed');
    }

    /**
     * @description Test font name validation
     */
    @IsTest
    static void testFontNameValidation() {
        // Test with supported fonts
        PdfText pdfText1 = new PdfText('Test', 100, 200, 12, 'normal', '000000', PdfConstants.FONT_HELVETICA);
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText1.fontName, 'Helvetica font should be accepted');

        PdfText pdfText2 = new PdfText('Test', 100, 200, 12, 'normal', '000000', PdfConstants.FONT_HELVETICA_BOLD);
        System.assertEquals(PdfConstants.FONT_HELVETICA_BOLD, pdfText2.fontName, 'Helvetica Bold font should be accepted');

        PdfText pdfText3 = new PdfText('Test', 100, 200, 12, 'normal', '000000', PdfConstants.FONT_COURIER);
        System.assertEquals(PdfConstants.FONT_COURIER, pdfText3.fontName, 'Courier font should be accepted');

        PdfText pdfText4 = new PdfText('Test', 100, 200, 12, 'normal', '000000', PdfConstants.FONT_COURIER_BOLD);
        System.assertEquals(PdfConstants.FONT_COURIER_BOLD, pdfText4.fontName, 'Courier Bold font should be accepted');

        // Test with unsupported font
        PdfText pdfText5 = new PdfText('Test', 100, 200, 12, 'normal', '000000', 'Comic Sans');
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText5.fontName, 'Unsupported font should default to Helvetica');

        // Test with null font
        PdfText pdfText6 = new PdfText('Test', 100, 200, 12, 'normal', '000000', null);
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText6.fontName, 'Null font should default to Helvetica');

        // Test with empty font
        PdfText pdfText7 = new PdfText('Test', 100, 200, 12, 'normal', '000000', '');
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText7.fontName, 'Empty font should default to Helvetica');

        // Test with spaces
        PdfText pdfText8 = new PdfText('Test', 100, 200, 12, 'normal', '000000', '  ' + PdfConstants.FONT_HELVETICA + '  ');
        System.assertEquals(PdfConstants.FONT_HELVETICA, pdfText8.fontName, 'Font with spaces should be trimmed');
    }
}
