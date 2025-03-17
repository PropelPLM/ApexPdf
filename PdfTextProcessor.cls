@SuppressWarnings('PMD.ExcessiveParameterList, PMD.CognitiveComplexity')
/**
 * @description Class to handle text processing for PDF generation
 * @author Propel PLM Team
 */
public with sharing class PdfTextProcessor {

    /**
     * @description Processes text for PDF rendering with wrapping if needed
     * @param text The text to process
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @param options Text rendering options including max width, font size, etc.
     * @return List<PdfText> List of processed text elements with proper positioning
     */
    public static List<PdfText> processText(String text, Integer x, Integer y, Pdf.TextOptions options) {
        return processText(text, x, y, options, null);
    }

    /**
     * @description Processes text for PDF rendering with wrapping if needed and custom lastY position
     * @param text The text to process
     * @param x The x-coordinate (from left) in points
     * @param y The y-coordinate (from top) in points
     * @param options Text rendering options including max width, font size, etc.
     * @param lastY The last Y position for intelligent positioning
     * @return List<PdfText> List of processed text elements with proper positioning
     */
    public static List<PdfText> processText(String text, Integer x, Integer y, Pdf.TextOptions options, Integer lastY) {
        List<PdfText> result = new List<PdfText>();

        // Initialize text position
        Integer yPos = y;
        if (yPos == null) {
            Integer lineHeight = getLineHeight(options);
            yPos = lastY != null ? lastY + lineHeight : PdfConstants.PAGE_MARGIN;
        }

        // Set default x position if not specified
        if (x == null) {
            x = PdfConstants.PAGE_MARGIN;
        }

        System.debug(LoggingLevel.FINE, 'Processing text: text=' + text + ', x=' + x + ', y=' + yPos +
                     ', maxWidth=' + (options != null ? String.valueOf(options.maxWidth) : 'null'));

        // Handle different text types (headings vs regular text)
        if (options != null && options.maxWidth != null) {
            System.debug('Processing text with fontSize=' + options.fontSize + ', fontStyle=' + options.fontStyle);

            // For headings, don't wrap text
            if (options.fontSize == PdfConstants.H1_FONT_SIZE ||
                options.fontSize == PdfConstants.H2_FONT_SIZE ||
                options.fontSize == PdfConstants.H3_FONT_SIZE) {

                System.debug('Adding heading text: ' + text);
                Integer lineHeight = getLineHeight(options);

                // Check if we need a new page (caller will handle this)
                if (yPos + lineHeight > (PdfConstants.PAGE_HEIGHT - PdfConstants.PAGE_MARGIN)) {
                    // Return with a flag indicating page break needed
                    PdfText element = new PdfText(text, x, yPos, options.fontSize, options.fontStyle, '000000');
                    element.needsPageBreak = true;
                    result.add(element);
                    return result;
                }

                // Create text element with original coordinates
                // The conversion to PDF coordinates will happen in the Pdf class
                PdfText element = new PdfText(text, x, yPos, options.fontSize, options.fontStyle, '000000');
                result.add(element);
            } else {
                // Handle regular text with wrapping
                result = wrapText(text, x, yPos, options);
            }
        } else {
            // Simple text with no wrapping
            Integer fontSize = options != null && options.fontSize != null ?
                              options.fontSize : PdfConstants.DEFAULT_FONT_SIZE;
            // For font style, we'll set a default here but the Pdf class
            // will override it with the document-level font style if needed
            String fontStyle = options != null && options.fontStyle != null ?
                              options.fontStyle : PdfConstants.STYLE_NORMAL;

            System.debug(LoggingLevel.ERROR, '**** PdfTextProcessor creating text with fontStyle=' + fontStyle);

            PdfText element = new PdfText(text, x, yPos, fontSize, fontStyle, '000000');
            System.debug(LoggingLevel.ERROR, 'CREATED TEXT ELEMENT: "' + text + '" with fontStyle=' + fontStyle);
            result.add(element);
        }

        return result;
    }

    /**
     * @description Wraps text to fit within the specified width
     * @param text The text to wrap
     * @param x The starting x-coordinate
     * @param y The starting y-coordinate
     * @param options Text options including maxWidth
     * @return List<PdfText> The list of text elements after wrapping
     */
    private static List<PdfText> wrapText(String text, Integer x, Integer y, Pdf.TextOptions options) {
        List<PdfText> result = new List<PdfText>();

        // Split text into words for wrapping
        List<String> words = text.split(' ');
        String currentLine = '';
        Integer currentY = y;
        // No need to track currentX separately from x since we'll modify x directly

        // Set defaults if options are null
        Integer fontSize = options != null && options.fontSize != null ?
                          options.fontSize : PdfConstants.DEFAULT_FONT_SIZE;
        String fontStyle = options != null && options.fontStyle != null ?
                          options.fontStyle : PdfConstants.STYLE_NORMAL;
        // Set default max width with a safety margin to ensure text doesn't go off the page
        // Use a slightly smaller width than the full page width by adding extra margin
        Integer defaultMaxWidth = PdfConstants.PAGE_WIDTH - (2 * PdfConstants.PAGE_MARGIN) - 10; // 10pt safety margin
        Integer maxWidth = options != null && options.maxWidth != null ?
                          options.maxWidth : defaultMaxWidth;

        // Calculate first line max width differently to account for starting position
        Integer firstLineMaxWidth;
        if (x > PdfConstants.PAGE_MARGIN) {
            // For the first line, adjust maxWidth based on the starting X position
            firstLineMaxWidth = PdfConstants.PAGE_WIDTH - PdfConstants.PAGE_MARGIN - x;
            System.debug(LoggingLevel.FINE, 'First line available width: ' + firstLineMaxWidth +
                        ' (reduced from ' + maxWidth + ' due to X position ' + x + ')');
        } else {
            firstLineMaxWidth = maxWidth;
        }

        // Initialize current max width to the first line max width
        Integer currentMaxWidth = firstLineMaxWidth;

        // Get line height
        Integer lineHeight = getLineHeight(options);

        // Debug the wrapping parameters
        System.debug(LoggingLevel.FINE, 'Text wrapping parameters: firstLineMaxWidth=' + firstLineMaxWidth +
                    ', maxWidth=' + maxWidth + ', x=' + x +
                    ', fontSize=' + fontSize + ', fontStyle=' + fontStyle);

        for (String word : words) {
            // Calculate width using improved estimation that accounts for font size
            // and different character widths in proportional fonts
            Decimal currentLineWidth = estimateTextWidth(currentLine, fontSize, fontStyle);
            Decimal wordWithSpaceWidth = estimateTextWidth(' ' + word, fontSize, fontStyle);

            // Check if adding this word would exceed the current max width
            // If so, we'll create a wrapped line that starts at the left margin
            if (currentLine != '' && (currentLineWidth + wordWithSpaceWidth > currentMaxWidth)) {
                // Line would be too long, add current line to result
                PdfText lineElement = new PdfText(currentLine, x, currentY, fontSize, fontStyle, '000000');
                result.add(lineElement);

                // Start new line
                currentLine = word;
                currentY += lineHeight;

                // Determine X position for the next line based on wrapToXPosition property
                if (options != null && options.wrapToXPosition != null) {
                    // If wrapToXPosition is specified, use that value (like left margin for traditional paragraphs)
                    x = options.wrapToXPosition;
                }
                // If wrapToXPosition is null, maintain the current X position (default behavior)
                // This is ideal for column-based layouts where text should stay within its column

                // After the first line is processed, use the full maxWidth for subsequent lines
                currentMaxWidth = maxWidth;

                // Check if we need a page break (caller will handle this)
                if (currentY > (PdfConstants.PAGE_HEIGHT - PdfConstants.PAGE_MARGIN)) {
                    PdfText element = new PdfText(currentLine, x, currentY, fontSize, fontStyle, '000000');
                    element.needsPageBreak = true;
                    result.add(element);
                    return result;
                }
            } else {
                // Add word to current line
                if (currentLine == '') {
                    currentLine = word;
                } else {
                    currentLine += ' ' + word;
                }
            }
        }

        // Add the final line if not empty
        if (currentLine != '') {
            PdfText lineElement = new PdfText(currentLine, x, currentY, fontSize, fontStyle, '000000');
            result.add(lineElement);
        }

        return result;
    }

    /**
     * @description Public method to estimate text width based on content and TextOptions
     * @param text The text to estimate width for
     * @param options The text options containing font size and style
     * @return Integer The estimated width in points
     */
    public static Integer estimateTextWidth(String text, Pdf.TextOptions options) {
        Integer fontSize = options != null && options.fontSize != null ? options.fontSize : PdfConstants.DEFAULT_FONT_SIZE;
        String fontStyle = options != null && options.fontStyle != null ? options.fontStyle : PdfConstants.STYLE_NORMAL;

        // Calculate the width
        Decimal width = estimateTextWidth(text, fontSize, fontStyle);

        // Convert the decimal result to integer for simpler handling
        Integer roundedWidth = (Integer)Math.round(width);

        return roundedWidth;
    }

    /**
     * @description Estimates text width based on content, font size and style
     * More accurate than a simple character count * fixed width
     * @param text The text to estimate width for
     * @param fontSize The font size in points
     * @param fontStyle The font style (normal, bold, italic, etc.)
     * @return Decimal The estimated width in points
     */
    private static Decimal estimateTextWidth(String text, Integer fontSize, String fontStyle) {
        if (text == null || text == '') {
            return 0;
        }

        // Base multiplier on standard 12pt font
        Decimal fontSizeMultiplier = fontSize / 12.0;

        // Start with base character width estimate
        Decimal baseEstimate = PdfConstants.CHAR_WIDTH_ESTIMATE;

        // Apply style-specific adjustments
        if (fontStyle == PdfConstants.STYLE_BOLD || fontStyle == PdfConstants.STYLE_BOLD_ITALIC) {
            // Bold text is wider
            baseEstimate *= 1.1;
        }

        if (fontStyle == PdfConstants.STYLE_ITALIC || fontStyle == PdfConstants.STYLE_BOLD_ITALIC) {
            // Italic text can be wider due to slant and ligature changes
            baseEstimate *= 1.08;
        }

        // Count character types for better proportional font estimation
        // Add detailed logging for the character-based width estimation
        Integer narrowChars = 0; // i,l,t,f,j,I,.,:,;,',-
        Integer wideChars = 0;   // m,w,M,W,O,G,Q

        for (Integer i = 0; i < text.length(); i++) {
            String c = text.substring(i, i+1);
            if ('iltfjI.,:\';\'-'.contains(c)) {
                narrowChars++;
            } else if ('mwMWOGQS'.contains(c)) {
                wideChars++;
            }
        }

        // Apply character-specific adjustments
        Decimal narrowAdjustment = narrowChars * (baseEstimate * 0.55); // Narrow chars are ~60% of standard width
        Decimal wideAdjustment = wideChars * (baseEstimate * 1.45);    // Wide chars are ~150% of standard width
        Decimal normalAdjustment = (text.length() - narrowChars - wideChars) * baseEstimate;

        // Calculate total estimated width with font size scaling
        Decimal totalEstimate = (narrowAdjustment + wideAdjustment + normalAdjustment) * fontSizeMultiplier;

        // Keep a much simpler debug message for regular troubleshooting
        if (text.length() > 50) {
            System.debug(LoggingLevel.FINE, 'Estimated width for long text with style "' + fontStyle + '": ' + totalEstimate + ' points');
        }

        return totalEstimate;
    }

    /**
     * @description Calculates the line height based on font size and style
     * @param options The text options containing font size and style
     * @return Integer The calculated line height in points
     */
    public static Integer getLineHeight(Pdf.TextOptions options) {
        Integer fontSize = options != null && options.fontSize != null ?
                          options.fontSize : PdfConstants.DEFAULT_FONT_SIZE;

        // For headings, add extra spacing based on heading level
        Decimal ratio = PdfConstants.LINE_HEIGHT_RATIO;
        if (fontSize == PdfConstants.H1_FONT_SIZE) {
            ratio = PdfConstants.LINE_HEIGHT_RATIO * 1.1; // 1.32 as per memory
        } else if (fontSize == PdfConstants.H2_FONT_SIZE) {
            ratio = PdfConstants.LINE_HEIGHT_RATIO * 1.08;
        } else if (fontSize == PdfConstants.H3_FONT_SIZE) {
            ratio = PdfConstants.LINE_HEIGHT_RATIO * 1.05;
        }

        return (Integer)(fontSize * ratio);
    }

    /**
     * @description Converts from top-down Y coordinates (user space) to bottom-up (PDF space)
     * @param y The Y coordinate in user space (from top)
     * @param fontSize The font size to account for baseline positioning
     * @return Integer The converted Y coordinate in PDF space
     */
    public static Integer convertToPdfY(Integer y, Integer fontSize) {
        // PDF coordinates start from bottom, while our input coordinates start from top
        // We need to: 1) Start from PAGE_HEIGHT, 2) Subtract y, 3) Subtract fontSize
        return PdfConstants.PAGE_HEIGHT - y - fontSize;
    }


    /**
     * @description Generates the content stream operators for text
     * @param textElements The list of text elements to generate content for
     * @return String The PDF content stream commands for text
     */
    public static String generateTextContentStream(List<PdfText> textElements) {
        String content = '';

        if (textElements == null || textElements.isEmpty()) {
            return content;
        }

        for (PdfText element : textElements) {
            // Convert from top-left origin to PDF's bottom-left origin
            Integer pdfY = convertToPdfY(element.y, element.fontSize);

            content += 'BT' + PdfConstants.LINE_BREAK;

            // Set font and size based on style
            // Map fontStyle to the appropriate font in the PDF resource dictionary
            String fontRef;
            if (element.fontStyle == PdfConstants.STYLE_BOLD) {
                fontRef = '/F2'; // Helvetica-Bold
            } else if (element.fontStyle == PdfConstants.STYLE_ITALIC) {
                fontRef = '/F5'; // Helvetica-Oblique
            } else if (element.fontStyle == PdfConstants.STYLE_BOLD_ITALIC) {
                fontRef = '/F6'; // Helvetica-BoldOblique
            } else {
                fontRef = '/F1'; // Helvetica (normal)
            }

            System.debug(LoggingLevel.FINE, 'Using font reference ' + fontRef + ' for style: ' + element.fontStyle);
            content += fontRef + ' ' + element.fontSize + ' Tf' + PdfConstants.LINE_BREAK;

            // Position text
            content += element.x + ' ' + pdfY + ' Td' + PdfConstants.LINE_BREAK;

            // Escape special characters in the text for PDF
            String escapedText = escapeTextForPdf(element.text);

            // Add the text
            content += '(' + escapedText + ') Tj' + PdfConstants.LINE_BREAK;
            content += 'ET' + PdfConstants.LINE_BREAK;
        }

        return content;
    }

    /**
     * @description Escapes text for PDF content stream
     * @param text The text to escape
     * @return String The escaped text
     */
    private static String escapeTextForPdf(String text) {
        if (text == null) {
            return '';
        }

        // Escape special characters in PDF
        String escaped = text.replace('\\', '\\\\')
                            .replace('(', '\\(')
                            .replace(')', '\\)')
                            .replace('\r\n', ' ')
                            .replace('\n', ' ')
                            .replace('\r', ' ');
        return escaped;
    }
}
