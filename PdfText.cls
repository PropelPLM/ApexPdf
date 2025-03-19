@SuppressWarnings('PMD.ExcessiveParameterList, PMD.NcssConstructorCount')
/**
 * @description Class representing a text element in a PDF document
 * @author Propel PLM
 */
public with sharing class PdfText {
    public String text;
    public Integer x;
    public Integer y;
    public Integer fontSize;
    public String fontStyle;
    public String textColor = '000000';  // Default black
    public String fontName = PdfConstants.FONT_HELVETICA; // Default font
    public Boolean needsPageBreak = false;

    // Transformation properties
    public Decimal rotationAngle = 0;     // Rotation angle in degrees
    public Decimal scaleX = 1.0;          // Horizontal scale factor
    public Decimal scaleY = 1.0;          // Vertical scale factor
    public Decimal opacity = 1.0;         // Opacity (1.0 = fully opaque, 0.0 = fully transparent)

    /**
     * @description Constructor for PdfText
     * @param text The text content
     * @param x The x-coordinate in points
     * @param y The y-coordinate in points
     * @param fontSize The font size in points
     * @param fontStyle The font style (normal or bold)
     */
    public PdfText(String text, Integer x, Integer y, Integer fontSize, String fontStyle) {
        this(text, x, y, fontSize, fontStyle, '000000', PdfConstants.FONT_HELVETICA); // Default to black, Helvetica font
    }

    /**
     * @description Constructor for PdfText with color
     * @param text The text content
     * @param x The x-coordinate in points
     * @param y The y-coordinate in points
     * @param fontSize The font size in points
     * @param fontStyle The font style (normal or bold)
     * @param textColor The text color as hex RGB string (e.g., '000000' for black)
     */
    public PdfText(String text, Integer x, Integer y, Integer fontSize, String fontStyle, String textColor) {
        this(text, x, y, fontSize, fontStyle, textColor, PdfConstants.FONT_HELVETICA);
    }

    /**
     * @description Constructor for PdfText with color and font
     * @param text The text content
     * @param x The x-coordinate in points
     * @param y The y-coordinate in points
     * @param fontSize The font size in points
     * @param fontStyle The font style (normal or bold)
     * @param textColor The text color as hex RGB string (e.g., '000000' for black)
     * @param fontName The font name to use (Helvetica or Arial)
     */
    public PdfText(String text, Integer x, Integer y, Integer fontSize, String fontStyle, String textColor, String fontName) {
        this.text = text;
        this.x = x;
        this.y = y;
        this.fontSize = fontSize;
        this.fontStyle = fontStyle;

        // Process text color
        if (textColor != null && textColor.trim() != '') {
            String colorTrimmed = textColor.trim();
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

        // Process font name
        if (fontName != null && fontName.trim() != '') {
            String fontTrimmed = fontName.trim();
            // Check if it's a supported font
            if (fontTrimmed == PdfConstants.FONT_HELVETICA ||
                fontTrimmed == PdfConstants.FONT_HELVETICA_BOLD ||
                fontTrimmed == PdfConstants.FONT_COURIER ||
                fontTrimmed == PdfConstants.FONT_COURIER_BOLD) {
                this.fontName = fontTrimmed;
            } else {
                System.debug(LoggingLevel.WARN, 'Unsupported font name: ' + fontTrimmed + '. Using default Helvetica.');
                this.fontName = PdfConstants.FONT_HELVETICA;
            }
        } else {
            this.fontName = PdfConstants.FONT_HELVETICA;
        }
    }

    /**
     * @description Sets the rotation angle for this text element
     * @param angle Rotation angle in degrees (0-360)
     * @return The current PdfText instance for method chaining
     */
    public PdfText setRotation(Decimal angle) {
        this.rotationAngle = Math.mod(angle.intValue(), 360);
        return this;
    }

    /**
     * @description Sets the scale factors for this text element
     * @param scaleX Horizontal scale factor (1.0 = normal size)
     * @param scaleY Vertical scale factor (1.0 = normal size)
     * @return The current PdfText instance for method chaining
     */
    public PdfText setScale(Decimal scaleX, Decimal scaleY) {
        this.scaleX = scaleX > 0 ? scaleX : 1.0;
        this.scaleY = scaleY > 0 ? scaleY : 1.0;
        return this;
    }

    /**
     * @description Sets uniform scaling for this text element
     * @param scale Scale factor to apply to both dimensions (1.0 = normal size)
     * @return The current PdfText instance for method chaining
     */
    public PdfText setScale(Decimal scale) {
        return setScale(scale, scale);
    }

    /**
     * @description Sets the opacity for this text element
     * @param opacity Opacity value between 0.0 (transparent) and 1.0 (opaque)
     * @return The current PdfText instance for method chaining
     */
    public PdfText setOpacity(Decimal opacity) {
        this.opacity = Math.max(0.0, Math.min(1.0, opacity));
        return this;
    }
}
