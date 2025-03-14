/**
 * @description Class to represent an image in a PDF document
 * @author Propel PLM
 */
public with sharing class PdfImage {
    public String imageId;      // Unique ID for the image
    public String format;       // Image format (JPEG, PNG)
    public Blob imageData;      // Raw image data
    public Integer x;           // X position
    public Integer y;           // Y position
    public Integer width;       // Display width
    public Integer height;      // Display height

    /**
     * @description Constructor for a PDF image element
     * @param imageId Unique identifier for the image
     * @param format Image format (JPEG, PNG)
     * @param imageData Raw image data
     * @param x X position
     * @param y Y position
     * @param width Display width
     * @param height Display height
     */
    public PdfImage(String imageId, String format, Blob imageData, Integer x, Integer y, Integer width, Integer height) {
        this.imageId = imageId;
        this.format = format;
        this.imageData = imageData;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }
}
