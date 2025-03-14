/**
 * @description Test class for PdfImageProcessor
 * @author Propel PLM
 */
@isTest
private class PdfImageProcessorTest {

    @isTest
    static void testProcessJpegImage() {
        // Create a mock JPEG image blob (just a placeholder for testing)
        Blob imageData = Blob.valueOf('test jpeg data');

        // Test JPEG processing
        Map<String, Object> result = PdfImageProcessor.processImage(imageData, 'JPEG');

        // Validate results
        System.assertEquals(PdfConstants.FORMAT_JPEG, result.get('format'), 'Format should be normalized to JPEG');
        System.assertEquals('[/ASCIIHexDecode /DCTDecode]', result.get('filter'), 'JPEG should use DCTDecode filter');
        System.assertEquals('/DeviceRGB', result.get('colorSpace'), 'JPEG should use DeviceRGB color space');

        // Validate hex data
        String hexData = (String)result.get('hexData');
        System.assert(hexData.endsWith('>'), 'Hex data should end with >');
    }

    @isTest
    static void testProcessPngImage() {
        // Create a mock PNG image blob (just a placeholder for testing)
        Blob imageData = Blob.valueOf('test png data');

        // Test PNG processing
        Map<String, Object> result = PdfImageProcessor.processImage(imageData, 'PNG');

        // Validate results
        System.assertEquals(PdfConstants.FORMAT_PNG, result.get('format'), 'Format should be normalized to PNG');
        System.assertEquals('[/ASCIIHexDecode /FlateDecode]', result.get('filter'), 'PNG should use FlateDecode filter');
        System.assertEquals('/DeviceRGB', result.get('colorSpace'), 'PNG should use DeviceRGB color space');
    }

    @isTest
    static void testProcessJpgImage() {
        // Test JPG processing (should normalize to JPEG)
        Blob imageData = Blob.valueOf('test jpg data');
        Map<String, Object> result = PdfImageProcessor.processImage(imageData, 'JPG');

        // Validate format normalization
        System.assertEquals(PdfConstants.FORMAT_JPEG, result.get('format'), 'JPG should be normalized to JPEG');
    }

    @isTest
    static void testProcessUnknownFormat() {
        // Test unknown format processing
        Blob imageData = Blob.valueOf('test unknown format data');
        Map<String, Object> result = PdfImageProcessor.processImage(imageData, 'GIF');

        // Should default to treating as JPEG
        System.assertEquals('GIF', result.get('format'), 'Format should remain as provided');
        System.assertEquals('[/ASCIIHexDecode /DCTDecode]', result.get('filter'), 'Unknown format should default to JPEG filters');
    }

    @isTest
    static void testGenerateImageDictionary() {
        // Create test image info
        Map<String, Object> imageInfo = new Map<String, Object>{
            'filter' => '[/ASCIIHexDecode /DCTDecode]',
            'colorSpace' => '/DeviceRGB',
            'width' => 100,
            'height' => 200,
            'length' => 1000,
            'bitsPerComponent' => 8
        };

        // Generate image dictionary
        String dictionary = PdfImageProcessor.generateImageDictionary(imageInfo);

        // Validate dictionary content
        System.assert(dictionary.contains('/Type /XObject'), 'Dictionary should include XObject type');
        System.assert(dictionary.contains('/Subtype /Image'), 'Dictionary should include Image subtype');
        System.assert(dictionary.contains('/Width 100'), 'Dictionary should include correct width');
        System.assert(dictionary.contains('/Height 200'), 'Dictionary should include correct height');
        System.assert(dictionary.contains('/BitsPerComponent 8'), 'Dictionary should include bits per component');
        System.assert(dictionary.contains('/Filter [/ASCIIHexDecode /DCTDecode]'), 'Dictionary should include filter');
        System.assert(dictionary.contains('/Length 1000'), 'Dictionary should include length');
    }

    @isTest
    static void testWriteJpegImage() {
        // Create mock JPEG image data
        Blob imageData = Blob.valueOf('test jpeg image data');

        // Create a PdfImage object
        PdfImage image = new PdfImage(
            'testImage',
            PdfConstants.FORMAT_JPEG,
            imageData,
            50, // x position
            100, // y position
            200, // width
            150  // height
        );

        // Test the writeImage method with object number 5
        String imageObject = PdfImageProcessor.writeImage(image, 5);

        // Validate the results
        System.assert(imageObject.startsWith('5 0 obj'), 'Object should start with object number definition');
        System.assert(imageObject.contains('/Type /XObject'), 'Object should contain XObject type');
        System.assert(imageObject.contains('/Subtype /Image'), 'Object should contain Image subtype');
        System.assert(imageObject.contains('/Name /testImage'), 'Object should contain correct image ID');
        System.assert(imageObject.contains('/Width 200'), 'Object should contain correct width');
        System.assert(imageObject.contains('/Height 150'), 'Object should contain correct height');
        System.assert(imageObject.contains('/Filter [/ASCIIHexDecode /DCTDecode]'), 'Object should contain JPEG filter');
        System.assert(imageObject.contains('/ColorSpace /DeviceRGB'), 'Object should contain RGB color space');
        System.assert(imageObject.contains('/BitsPerComponent 8'), 'Object should contain bits per component');

        // Check stream markers
        System.assert(imageObject.contains('stream'), 'Object should contain stream marker');
        System.assert(imageObject.contains('endstream'), 'Object should contain endstream marker');
        System.assert(imageObject.contains('endobj'), 'Object should contain endobj marker');

        // Verify encoded data is included
        String hexEncoded = EncodingUtil.convertToHex(imageData) + '>';
        System.assert(imageObject.contains(hexEncoded), 'Object should contain hex-encoded image data');
    }

    @isTest
    static void testWritePngImage() {
        // Create mock PNG image data
        Blob imageData = Blob.valueOf('test png image data');

        // Create a PdfImage object
        PdfImage image = new PdfImage(
            'pngImage',
            PdfConstants.FORMAT_PNG,
            imageData,
            75, // x position
            150, // y position
            300, // width
            250  // height
        );

        // Test the writeImage method with object number 10
        String imageObject = PdfImageProcessor.writeImage(image, 10);

        // Validate the results
        System.assert(imageObject.startsWith('10 0 obj'), 'Object should start with object number definition');
        System.assert(imageObject.contains('/Name /pngImage'), 'Object should contain correct image ID');
        System.assert(imageObject.contains('/Width 300'), 'Object should contain correct width');
        System.assert(imageObject.contains('/Height 250'), 'Object should contain correct height');
        System.assert(imageObject.contains('/Filter [/ASCIIHexDecode /FlateDecode]'), 'Object should contain PNG filter');

        // Verify encoded data is included
        String hexEncoded = EncodingUtil.convertToHex(imageData) + '>';
        System.assert(imageObject.contains(hexEncoded), 'Object should contain hex-encoded image data');
    }
}
