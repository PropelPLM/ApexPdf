/**
 * @description Constants for PDF generation
 * Contains all constants used in PDF generation including page dimensions,
 * font sizes, text styles, and PDF structure constants
 */
public class PdfConstants {
    // Page dimensions and margins
    public static final Integer PAGE_WIDTH = 612;   // US Letter width in points
    public static final Integer PAGE_HEIGHT = 792;  // US Letter height in points
    public static final Integer PAGE_MARGIN = 72;   // 1 inch margin
    public static final Decimal CHAR_WIDTH_ESTIMATE = 5.5;  // Estimated width of each character in points (increased to ensure proper margin wrapping)
    public static final Decimal LINE_HEIGHT_RATIO = 1.2;  // Line height as a multiple of font size

    // Font sizes
    public static final Integer DEFAULT_FONT_SIZE = 12;  // Default font size in points
    public static final Integer H1_FONT_SIZE = 24;      // Heading 1 font size in points
    public static final Integer H2_FONT_SIZE = 20;      // Heading 2 font size in points
    public static final Integer H3_FONT_SIZE = 16;      // Heading 3 font size in points

    // Text styles
    public static final String STYLE_NORMAL = 'normal';
    public static final String STYLE_BOLD = 'bold';
    public static final String STYLE_ITALIC = 'italic';
    public static final String STYLE_BOLD_ITALIC = 'bold italic';

    // Font constants
    public static final String FONT_HELVETICA = 'Helvetica';
    public static final String FONT_HELVETICA_BOLD = 'Helvetica-Bold';
    public static final String FONT_COURIER = 'Courier';
    public static final String FONT_COURIER_BOLD = 'Courier-Bold';

    // Image format constants
    public static final String FORMAT_JPEG = 'JPEG';
    public static final String FORMAT_PNG = 'PNG';

    // PDF structure constants
    public static final String PDF_HEADER = '%PDF-1.7\r\n%\u0080\u0081\u0082\u0083\r\n';
    public static final String LINE_BREAK = '\r\n';
    public static final String DICT_START = '<<' + LINE_BREAK;
    public static final String DICT_END = '>>' + LINE_BREAK;
    public static final String OBJ_END = 'endobj' + LINE_BREAK;
    public static final String STREAM_START = 'stream' + LINE_BREAK;
    public static final String STREAM_END = 'endstream' + LINE_BREAK;

    // PDF object types
    public static final String TYPE_CATALOG = '/Type /Catalog';
    public static final String TYPE_PAGES = '/Type /Pages';
    public static final String TYPE_PAGE = '/Type /Page';
    public static final String TYPE_XOBJECT = '/Type /XObject';
    public static final String TYPE_FONT = '/Type /Font';

    // PDF standard objects
    public static final Integer CATALOG_OBJ_NUM = 1;
    public static final Integer PAGES_OBJ_NUM = 2;
    public static final Integer FIRST_PAGE_OBJ_NUM = 3;

    // PDF resource dictionary templates
    public static final String PDF_STANDARD_RESOURCES =
        '/Resources <<\r\n'
        + '/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]\r\n'
        + '/Font <<\r\n'
        + '/F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\r\n'
        + '/F2 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\r\n'
        + '/F3 << /Type /Font /Subtype /Type1 /BaseFont /Courier >>\r\n'
        + '/F4 << /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>\r\n'
        + '/F5 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique >>\r\n'
        + '/F6 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-BoldOblique >>\r\n'
        + '/F7 << /Type /Font /Subtype /Type1 /BaseFont /Courier-Oblique >>\r\n'
        + '/F8 << /Type /Font /Subtype /Type1 /BaseFont /Courier-BoldOblique >>\r\n'
        + '>>\r\n';

}
