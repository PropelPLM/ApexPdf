@SuppressWarnings('PMD.ExcessiveParameterList')
/**
 * @description Wrapper class to hold PDF stream and offset information for building PDF documents
 * Used to track string content and byte offsets during PDF generation
 */
public with sharing class PdfStream {
    // Constants for PDF generation
    /**
     * The content of the PDF stream
     */
    public String pdfContent { get; set; }

    /**
     * The current byte offset in the stream
     */
    public Integer byteOffset { get; set; }

    /**
     * @description Constructor for creating a new PDF stream
     * @param pdfContent The initial content of the PDF stream
     * @param byteOffset The initial byte offset in the stream
     */
    public PdfStream(String pdfContent, Integer byteOffset) {
        this.pdfContent = pdfContent;
        this.byteOffset = byteOffset;
    }

    /**
     * @description Appends content to the PDF stream and tracks offset
     * @param content The content to append to the stream
     * @param offsetList Optional list to store the current offset
     * @return This PdfStream instance for method chaining
     */
    public PdfStream appendContent(String content, List<Integer> offsetList) {
        if (offsetList != null) {
            offsetList.add(this.byteOffset);
        }
        this.pdfContent += content;
        this.byteOffset += content.length();
        return this;
    }

    /**
     * @description Creates and writes the PDF catalog object (always object 1)
     * @param objectOffsets List to record object offsets
     * @return This PdfStream instance for method chaining
     */
    public PdfStream createCatalogObject(List<Integer> objectOffsets) {
        // Always create object 1 (the catalog)
        String catalogObj = PdfConstants.CATALOG_OBJ_NUM + ' 0 obj' + PdfConstants.LINE_BREAK
                          + PdfConstants.DICT_START
                          + PdfConstants.TYPE_CATALOG + PdfConstants.LINE_BREAK
                          + '/Pages ' + PdfConstants.PAGES_OBJ_NUM + ' 0 R' + PdfConstants.LINE_BREAK
                          + PdfConstants.DICT_END + PdfConstants.OBJ_END;
        return appendContent(catalogObj, objectOffsets);
    }

    /**
     * @description Creates and writes the PDF pages object (always object 2) with image resources
     * @param objectOffsets List to record object offsets
     * @param pageCount Number of pages in the document
     * @param imageElements List of image elements in the document
     * @param imageObjectNumbers Map of image IDs to their object numbers
     * @return This PdfStream instance for method chaining
     */
    public PdfStream createPagesObjectWithImages(List<Integer> objectOffsets, Integer pageCount,
                                      List<PdfImage> imageElements, Map<String, Integer> imageObjectNumbers) {
        String pagesObj = PdfConstants.PAGES_OBJ_NUM + ' 0 obj' + PdfConstants.LINE_BREAK
                        + PdfConstants.DICT_START
                        + PdfConstants.TYPE_PAGES + PdfConstants.LINE_BREAK
                        + '/Kids [';

        // Add references to all page objects
        List<String> pageRefs = new List<String>();
        for (Integer i = 0; i < pageCount; i++) {
            pageRefs.add(String.valueOf(3 + i) + ' 0 R');
        }
        pagesObj += String.join(pageRefs, ' ');

        // Build resource dictionary including image XObjects
        String resourceDict = PdfConstants.PDF_STANDARD_RESOURCES;

        // Add XObject dictionary if we have images
        if (imageElements != null && !imageElements.isEmpty()) {
            resourceDict += '/XObject <<\r\n';
            for (PdfImage image : imageElements) {
                String imageId = image.imageId;
                resourceDict += '/' + imageId + ' ' + String.valueOf(imageObjectNumbers.get(imageId)) + ' 0 R\r\n';
            }
            resourceDict += '>>\r\n';
        }

        resourceDict += '>>\r\n';

        pagesObj += ']' + PdfConstants.LINE_BREAK
                  + '/Count ' + pageCount + PdfConstants.LINE_BREAK
                  + resourceDict
                  + PdfConstants.DICT_END + PdfConstants.OBJ_END;

        return appendContent(pagesObj, objectOffsets);
    }

    /**
     * Creates a ContentVersion record with the given filename and this stream's PDF content
     * @param filename The name of the file
     * @return ContentVersion ID of the created record
     */
    public Id saveToCV(String filename) {
        ContentVersion cv = new ContentVersion();
        cv.Title = filename;
        cv.PathOnClient = filename + '.pdf';
        cv.VersionData = Blob.valueOf(this.pdfContent);
        cv.IsMajorVersion = true;

        insert cv; //NOPMD not permissionable
        system.debug(LoggingLevel.DEBUG, 'Document Version: ' + cv.Id);

        // Get ContentDocument Id
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        // Check if the document is already shared with the user
        List<ContentDocumentLink> existingLinks = [SELECT Id //NOPMD not permissionable
                                               FROM ContentDocumentLink
                                               WHERE ContentDocumentId = :conDocId
                                               AND LinkedEntityId = :UserInfo.getUserId()
                                               LIMIT 1];

        // Only create the link if it doesn't exist
        if (existingLinks.isEmpty()) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = conDocId;
            cdl.LinkedEntityId = UserInfo.getUserId();
            cdl.ShareType = 'V';  // V = Viewer permission. Allows viewing and downloading of a file

            insert cdl; //NOPMD not permissionable
        }

        return cv.Id;
    }
}
