/**
 * @description Handles image processing for PDF generation
 * @author Propel PLM
 */
public with sharing class PdfImageProcessor {

    /**
     * @description Processes an image for PDF embedding
     * @param imageData The raw image data
     * @param format The image format (JPEG, PNG)
     * @return Map<String, Object> containing processed image data and metadata
     */
    public static Map<String, Object> processImage(Blob imageData, String format) {
        Map<String, Object> result = new Map<String, Object>();

        // Normalize the format
        String normalizedFormat = normalizeFormat(format);
        result.put('format', normalizedFormat);

        // Convert image data to hex representation with '>' trailer
        String hexData = EncodingUtil.convertToHex(imageData) + '>';
        result.put('hexData', hexData);

        // Calculate length (including the '>' character)
        result.put('length', hexData.length());

        // Determine filter and color space based on format
        Map<String, String> filterInfo = getFilterInfo(normalizedFormat);
        result.put('filter', filterInfo.get('filter'));
        result.put('colorSpace', filterInfo.get('colorSpace'));

        return result;
    }

    /**
     * @description Normalizes the image format
     * @param format The format to normalize
     * @return String The normalized format (JPEG or PNG)
     */
    private static String normalizeFormat(String format) {
        // CRITICAL: Normalize the format to handle inconsistencies
        String normalizedFormat = (format != null) ? format.toUpperCase() : PdfConstants.FORMAT_JPEG;

        // Default to JPEG for common types or if missing
        if (normalizedFormat == 'JPG' || normalizedFormat == '') {
            normalizedFormat = PdfConstants.FORMAT_JPEG;
        }

        return normalizedFormat;
    }

    /**
     * @description Gets the appropriate filter and color space info for the image format
     * @param format The normalized image format
     * @return Map<String, String> containing filter and colorSpace information
     */
    private static Map<String, String> getFilterInfo(String format) {
        Map<String, String> result = new Map<String, String>();

        if (format.equalsIgnoreCase(PdfConstants.FORMAT_JPEG)) {
            // For JPEG, we need a filter array: first ASCIIHexDecode (to convert hex), then DCTDecode (to decompress JPEG)
            result.put('filter', '[/ASCIIHexDecode /DCTDecode]');
            result.put('colorSpace', '/DeviceRGB'); // Most JPEGs use RGB
        } else if (format.equalsIgnoreCase(PdfConstants.FORMAT_PNG)) {
            // For PNG, we need ASCIIHexDecode followed by FlateDecode
            result.put('filter', '[/ASCIIHexDecode /FlateDecode]');
            result.put('colorSpace', '/DeviceRGB'); // Default for most PNGs
        } else {
            // Default to JPEG handling for unknown formats
            result.put('filter', '[/ASCIIHexDecode /DCTDecode]');
            result.put('colorSpace', '/DeviceRGB');
        }

        return result;
    }

    /**
     * @description Generates the PDF image dictionary content
     * @param image The image information
     * @param width The width of the image in PDF
     * @param height The height of the image in PDF
     * @param hexData The hex-encoded image data
     * @return String The PDF image dictionary
     */
    public static String generateImageDictionary(Map<String, Object> imageInfo) {
        String filter = (String)imageInfo.get('filter');
        String colorSpace = (String)imageInfo.get('colorSpace');

        // Safe type conversions for numeric values
        Integer width = getIntegerValue(imageInfo, 'width');
        Integer height = getIntegerValue(imageInfo, 'height');
        Integer length = getIntegerValue(imageInfo, 'length');
        Integer bitsPerComponent = imageInfo.containsKey('bitsPerComponent') ?
                                   getIntegerValue(imageInfo, 'bitsPerComponent') : 8;

        return PdfConstants.DICT_START
             + PdfConstants.TYPE_XOBJECT + PdfConstants.LINE_BREAK
             + '/Subtype /Image' + PdfConstants.LINE_BREAK
             + '/Width ' + width + PdfConstants.LINE_BREAK
             + '/Height ' + height + PdfConstants.LINE_BREAK
             + '/ColorSpace ' + colorSpace + PdfConstants.LINE_BREAK
             + '/BitsPerComponent ' + bitsPerComponent + PdfConstants.LINE_BREAK
             + '/Filter ' + filter + PdfConstants.LINE_BREAK
             + '/Length ' + length + PdfConstants.LINE_BREAK
             + PdfConstants.DICT_END;
    }

    /**
     * @description Safely converts a map value to Integer
     * @param valueMap The map containing the value
     * @param key The key for the value
     * @return Integer The converted integer value
     */
    private static Integer getIntegerValue(Map<String, Object> valueMap, String key) {
        if (valueMap == null || !valueMap.containsKey(key)) {
            return 0;
        }

        Object value = valueMap.get(key);
        if (value instanceof Integer) {
            return (Integer)value;
        } else if (value instanceof Decimal) {
            return ((Decimal)value).intValue();
        } else if (value instanceof String) {
            try {
                return Integer.valueOf((String)value);
            } catch (Exception e) {
                System.debug('Error converting string to integer: ' + e.getMessage());
                return 0;
            }
        } else {
            // For any other type, try to convert to string first, then to Integer
            try {
                return Integer.valueOf(String.valueOf(value));
            } catch (Exception e) {
                System.debug('Error converting value to integer: ' + e.getMessage());
                return 0;
            }
        }
    }

    /**
     * @description Writes an image as a PDF object
     * @param image The PdfImage containing image data and properties
     * @param objNum The object number to assign to this image
     * @return String The complete PDF object representing the image
     */
    public static String writeImage(PdfImage image, Integer objNum) {
        System.debug('Writing image: id=' + image.imageId + ', format=' + image.format + ', size=' + image.imageData.size());
        System.debug('Using assigned object number ' + objNum + ' for image ' + image.imageId);

        // Set default image properties
        String filter;
        String colorSpace;
        String bitsPerComponent = '8';
        Integer dataSize = image.imageData.size();
        Integer binarySize = image.imageData.size(); // Size of the raw binary data

        // For debugging - check image size
        System.debug('Image dimensions: ' + image.width + 'x' + image.height + ', Data size: ' + dataSize + ' bytes');

        // Process the image to get filter, color space, and hex data
        Map<String, Object> imageInfo = processImage(image.imageData, image.format);
        filter = (String)imageInfo.get('filter');
        colorSpace = (String)imageInfo.get('colorSpace');
        String hexData = (String)imageInfo.get('hexData');

        // Safely convert length to Integer
        Integer encodedLength = 0;
        if (imageInfo.get('length') instanceof Integer) {
            encodedLength = (Integer)imageInfo.get('length');
        } else if (imageInfo.get('length') != null) {
            // Convert to string first for safety
            encodedLength = Integer.valueOf(String.valueOf(imageInfo.get('length')));
        }

        System.debug('Using ' + image.format + ' with filter: ' + filter);

        // Add image dimensions and create complete image info
        imageInfo.put('width', image.width);
        imageInfo.put('height', image.height);
        imageInfo.put('bitsPerComponent', bitsPerComponent);

        // Build the image XObject dictionary using our dictionary generator
        String imageDictionary = generateImageDictionary(imageInfo);

        // Construct the complete object string
        String content = objNum.toString() + ' 0 obj\r\n' + imageDictionary + 'stream\r\n';

        // Add a Name parameter to ensure image can be properly referenced
        content = content.replace('/Subtype /Image' + PdfConstants.LINE_BREAK,
                               '/Subtype /Image' + PdfConstants.LINE_BREAK +
                               '/Name /' + image.imageId + PdfConstants.LINE_BREAK);

        // The hexData already has the trailing '>' character required by ASCIIHexDecode
        System.debug('Using pre-processed hex data: ' + hexData.substring(0, Math.min(30, hexData.length())) + '... (truncated)');

        // Add the encoded data to the stream
        content += hexData;

        // End stream and object
        content += '\r\nendstream\r\nendobj\r\n';

        System.debug('Created image object ' + objNum + ' with length ' + binarySize + ' bytes');
        System.debug('Image dictionary (abbreviated): Type=/XObject, Subtype=/Image, Width=' + image.width +
                   ', Height=' + image.height + ', Filter=' + filter + ', ColorSpace=' + colorSpace);

        return content;
    }
}
