@SuppressWarnings('PMD.ExcessiveParameterList')
/**
 * @description Represents a rectangle element in a PDF document
 * @author Ron Hess
 * @since 2024
 */
public class PdfRect {
    /**
     * X-coordinate in points from left edge
     */
    public Integer x { get; set; }

    /**
     * Y-coordinate in points from top edge (will be converted to PDF coordinates)
     */
    public Integer y { get; set; }

    /**
     * Width in points
     */
    public Integer width { get; set; }

    /**
     * Height in points
     */
    public Integer height { get; set; }

    /**
     * Fill style: 'S' for stroke, 'F' for fill, 'B' for both
     */
    public String fillStyle { get; set; }

    /**
     * Line color in hex format (e.g., '000000' for black)
     */
    public String lineColor { get; set; }

    /**
     * Fill color in hex format (e.g., 'FFFFFF' for white)
     */
    public String fillColor { get; set; }

    /**
     * Line width in points
     */
    public Integer lineWidth { get; set; }

    /**
     * @description Default constructor
     */
    public PdfRect() {
        this.fillStyle = 'S'; // Default to stroke
        this.lineColor = '000000'; // Default to black
        this.fillColor = '000000'; // Default to black
        this.lineWidth = 1; // Default to 1pt
    }

    /**
     * @description Constructor with basic rectangle properties
     * @param x X-coordinate in points from left edge
     * @param y Y-coordinate in points from top edge
     * @param width Width in points
     * @param height Height in points
     * @param fillStyle Fill style ('S' for stroke, 'F' for fill, 'B' for both)
     */
    public PdfRect(Integer x, Integer y, Integer width, Integer height, String fillStyle) {
        this();
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.fillStyle = fillStyle;
    }

    /**
     * @description Constructor with all rectangle properties
     * @param x X-coordinate in points from left edge
     * @param y Y-coordinate in points from top edge
     * @param width Width in points
     * @param height Height in points
     * @param fillStyle Fill style ('S' for stroke, 'F' for fill, 'B' for both)
     * @param lineColor Line color in hex format
     * @param fillColor Fill color in hex format
     * @param lineWidth Line width in points
     */
    public PdfRect(Integer x, Integer y, Integer width, Integer height,
                   String fillStyle, String lineColor, String fillColor, Integer lineWidth) {
        this(x, y, width, height, fillStyle);
        this.lineColor = lineColor;
        this.fillColor = fillColor;
        this.lineWidth = lineWidth;
    }

    /**
     * @description Generates the PDF drawing command for this rectangle
     * @return The PDF command string to draw this rectangle
     */
    public String toPdfCommand() {
        // Convert coordinates from top-down to PDF's bottom-up coordinate system
        Integer pdfY = PdfConstants.PAGE_HEIGHT - this.y - this.height;

        // Build the drawing command
        String cmd = '';

        // Set colors and line width
        if (this.fillStyle == 'F' || this.fillStyle == 'B') {
            // Set fill color
            cmd += this.rgbHexToPdfColorCommand(this.fillColor, true) + '\n';
        }

        // Set stroke color and width
        if (this.fillStyle == 'S' || this.fillStyle == 'B') {
            cmd += this.rgbHexToPdfColorCommand(this.lineColor, false) + '\n';
            // Ensure line width is never null
            Integer width = (this.lineWidth != null) ? this.lineWidth : 1;
            cmd += width + ' w\n'; // Set line width
        }

        // Add rectangle path and drawing operation
        cmd += this.x + ' ' + pdfY + ' ' + this.width + ' ' + this.height + ' re '; // Rectangle path

        // Apply the fill style
        if (this.fillStyle == 'S') {
            cmd += 'S'; // Stroke
        } else if (this.fillStyle == 'F') {
            cmd += 'f'; // Fill
        } else if (this.fillStyle == 'B') {
            cmd += 'B'; // Both fill and stroke
        } else {
            cmd += 'S'; // Default to stroke
        }

        return cmd;
    }

    /**
     * @description Converts RGB hex color to PDF color command
     * @param hexColor RGB color in hex format (e.g., 'FF0000' for red)
     * @param isFill Whether this is for fill (true) or stroke (false)
     * @return PDF color command string
     */
    private String rgbHexToPdfColorCommand(String hexColor, Boolean isFill) {
        if (hexColor == null || hexColor.length() != 6) {
            return isFill ? '0 0 0 rg' : '0 0 0 RG'; // Default to black
        }

        try {
            // Convert hex to RGB values (0-1)
            Decimal r = hexToDecimal(hexColor.substring(0, 2)) / 255.0;
            Decimal g = hexToDecimal(hexColor.substring(2, 4)) / 255.0;
            Decimal b = hexToDecimal(hexColor.substring(4, 6)) / 255.0;

            // Format to 3 decimal places with fixed decimal format
            String rStr = r.setScale(3).toPlainString();
            String gStr = g.setScale(3).toPlainString();
            String bStr = b.setScale(3).toPlainString();

            // Return PDF color command (lowercase for fill, uppercase for stroke)
            return rStr + ' ' + gStr + ' ' + bStr + (isFill ? ' rg' : ' RG');
        } catch (Exception e) {
            return isFill ? '0 0 0 rg' : '0 0 0 RG'; // Default to black
        }
    }

    /**
     * @description Converts a hex string to a decimal value
     * @param hex Hexadecimal string
     * @return Integer value
     */
    private Integer hexToDecimal(String hex) {
        String hexChars = '0123456789ABCDEF';
        hex = hex.toUpperCase();
        Integer val = 0;
        for (Integer i = 0; i < hex.length(); i++) {
            String hexChar = hex.substring(i, i+1);
            Integer charIndex = hexChars.indexOf(hexChar);
            if (charIndex == -1) {
                return 0; // Invalid character
            }
            val = val * 16 + charIndex;
        }
        return val;
    }
}
