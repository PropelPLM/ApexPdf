/**
 * @description Test class for AutoTable functionality
 * @author Ron Hess
 * @since 2025
 */
@isTest
private class AutoTableTest {

    /**
     * @description Tests basic table generation with default options
     */
    @isTest
    static void testBasicTableGeneration() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Add a title
        doc.h1('PDF Table Example', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);

        // Create test data
        List<Map<String, String>> data = createTestData();

        // Define columns
        List<AutoTable.Column> columns = createTestColumns();

        // Create and draw the table with default options
        doc.autoTable(columns, data);

        // Save the PDF document
        String filename = 'AutoTable_Test_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests table generation with custom styling options
     */
    @isTest
    static void testTableWithCustomStyles() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Create test data and columns
        List<Map<String, String>> data = createTestData();
        List<AutoTable.Column> columns = createTestColumns();

        // Configure custom options
        AutoTable.TableOptions options = new AutoTable.TableOptions();
        options.startY = doc.getCurrentY() + 20;
        options.theme = AutoTable.THEME_GRID;
        options.margin = 10;

        // Set custom styles
        options.headStyles.put('fillColor', 'FF0000'); // Red header background
        options.headStyles.put('textColor', 'FFFFFF'); // White header text
        options.bodyStyles.put('lineColor', '000000'); // Black grid lines

        // Create and draw the table
        doc.autoTable(columns, data, options);

        // Save the PDF
        String filename = 'AutoTable_CustomStyle_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests table with column width customization
     */
    @isTest
    static void testTableWithCustomColumnWidths() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Create test data
        List<Map<String, String>> data = createTestData();

        // Define columns with custom widths
        List<AutoTable.Column> columns = new List<AutoTable.Column>{
            new AutoTable.Column('ID', 'id', 50),
            new AutoTable.Column('Product Name', 'name', 200),
            new AutoTable.Column('Price', 'price', 100),
            new AutoTable.Column('Quantity', 'qty', 100)
        };

        // Configure options
        AutoTable.TableOptions options = new AutoTable.TableOptions();
        options.startY = doc.getCurrentY() + 20;

        // Create and draw the table
        doc.autoTable(columns, data, options);

        // Save the PDF
        String filename = 'AutoTable_CustomWidth_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests multi-page table with many rows
     */
    @isTest
    static void testMultiPageTable() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Add a title
        doc.h1('Multi-Page Table Test', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);

        // Create columns
        List<AutoTable.Column> columns = createTestColumns();

        // Create lots of data rows to force multiple pages
        List<Map<String, String>> largeData = new List<Map<String, String>>();

        // Add 50 rows to ensure it spans multiple pages
        for(Integer i = 1; i <= 50; i++) {
            largeData.add(new Map<String, String>{
                'id' => String.valueOf(i).leftPad(3, '0'),
                'name' => 'Product ' + String.fromCharArray(new List<Integer>{65 + Math.mod(i, 26)}),
                'price' => '$' + (i * 10 + 0.99),
                'qty' => String.valueOf(Math.mod(i * 3, 100))
            });
        }

        // Configure options
        AutoTable.TableOptions options = new AutoTable.TableOptions();
        options.startY = doc.getCurrentY() + 20;
        options.showHead = AutoTable.SHOW_EVERY_PAGE;

        // Create and draw the table
        doc.autoTable(columns, largeData, options);

        // Save the PDF
        String filename = 'AutoTable_MultiPage_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests different showHead options (firstPage and never)
     */
    @isTest
    static void testShowHeadOptions() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Create test data and columns
        List<Map<String, String>> data = createTestData();
        List<AutoTable.Column> columns = createTestColumns();

        // Test SHOW_FIRST_PAGE option
        AutoTable.TableOptions firstPageOptions = new AutoTable.TableOptions();
        firstPageOptions.startY = doc.getCurrentY() + 20;
        firstPageOptions.withShowHead(AutoTable.SHOW_FIRST_PAGE);

        // Create and draw the table with firstPage header option
        doc.autoTable(columns, data, firstPageOptions);

        // Test SHOW_NEVER option
        AutoTable.TableOptions neverOptions = new AutoTable.TableOptions();
        neverOptions.startY = doc.getCurrentY() + 20;
        neverOptions.withShowHead(AutoTable.SHOW_NEVER);
        neverOptions.withMargin(15); // Test withMargin method

        // Create and draw the table with never show header option
        doc.autoTable(columns, data, neverOptions);

        // Save the PDF
        String filename = 'AutoTable_ShowHeadOptions_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the AutoTable class directly (not through Pdf class)
     */
    @isTest
    static void testAutoTableClassMethods() {
        Test.startTest();

        // Test Column class with different constructors
        AutoTable.Column col1 = new AutoTable.Column();
        col1.title = 'Test Column';
        col1.dataKey = 'test_key';
        System.assertEquals('Test Column', col1.title, 'Column title should match');
        System.assertEquals('test_key', col1.dataKey, 'Column dataKey should match');

        // Test Column with two parameters
        AutoTable.Column col2 = new AutoTable.Column('Col2', 'key2');
        System.assertEquals('Col2', col2.title, 'Column title should match');
        System.assertEquals('key2', col2.dataKey, 'Column dataKey should match');

        // Test Column with full constructor and chained methods
        AutoTable.Column col3 = new AutoTable.Column('Col3', 'key3', 150);
        System.assertEquals(150, col3.width, 'Column width should match');

        // Test withWidth method
        col3.withWidth(200);
        System.assertEquals(200, col3.width, 'Column width should be updated');

        // Test withStyles method
        Map<String, Object> customStyles = new Map<String, Object>{
            'textColor' => 'blue',
            'fontStyle' => 'italic'
        };
        col3.withStyles(customStyles);
        System.assertEquals('blue', col3.styles.get('textColor'), 'Column style should be set correctly');

        // Test direct AutoTable creation
        AutoTable table = new AutoTable();
        table.addColumn('ID', 'id');
        table.addColumn('Name', 'name');
        System.assertEquals(2, table.columns.size(), 'Table should have 2 columns');

        // Add data to the table
        table.addRow(new Map<String, String>{
            'id' => '001',
            'name' => 'Item 1'
        });
        System.assertEquals(1, table.body.size(), 'Table should have 1 row');

        // Test table options
        table.options.withShowHead(AutoTable.SHOW_FIRST_PAGE);
        System.assertEquals(AutoTable.SHOW_FIRST_PAGE, table.options.showHead, 'showHead option should be set correctly');

        // Test striped theme
        table.options.theme = AutoTable.THEME_STRIPED;
        System.assertEquals(AutoTable.THEME_STRIPED, table.options.theme, 'Theme should be set correctly');

        Test.stopTest();
    }

    /**
     * @description Tests table with striped theme
     */
    @isTest
    static void testStripedThemeTable() {
        Test.startTest();

        // Create a new PDF document
        Pdf doc = new Pdf();

        // Create test data and columns
        List<Map<String, String>> data = createTestData();
        List<AutoTable.Column> columns = createTestColumns();

        // Configure options with striped theme
        AutoTable.TableOptions options = new AutoTable.TableOptions();
        options.startY = doc.getCurrentY() + 20;
        options.theme = AutoTable.THEME_STRIPED;

        // Customize the alternate row styles to test that code path
        options.alternateRowStyles.put('fillColor', 'EFEFEF'); // Light gray

        // Create and draw the table
        doc.autoTable(columns, data, options);

        // Save the PDF
        String filename = 'AutoTable_StripedTheme_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the getExample() method and additional TableOptions methods
     */
    @isTest
    static void testExampleTableAndAdditionalMethods() {
        Test.startTest();

        // Test the getExample static method
        AutoTable exampleTable = AutoTable.getExample();
        System.assertNotEquals(null, exampleTable, 'Example table should not be null');
        System.assertEquals(2, exampleTable.columns.size(), 'Example table should have 2 columns');
        System.assertEquals(2, exampleTable.body.size(), 'Example table should have 2 rows');

        // Test the withStartY method
        exampleTable.options.withStartY(100);
        System.assertEquals(100, exampleTable.options.startY, 'startY should be 100');

        // Create a PDF to test the full implementation
        Pdf doc = new Pdf();
        doc.h1('Example Table Test', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);

        // Set options using the withStartY method
        exampleTable.options.withStartY(doc.getCurrentY() + 20);

        // Create and draw the table
        doc.autoTable(exampleTable.columns, exampleTable.body, exampleTable.options);

        // Save the PDF
        String filename = 'AutoTable_Example_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the addFieldSet and addRecords methods
     */
    // Custom class with the same properties as FieldSetMember
    public class CustomFieldInfo {
        public String fieldPath { get; set; }
        public String label { get; set; }

        public CustomFieldInfo(String fieldPath, String label) {
            this.fieldPath = fieldPath;
            this.label = label;
        }
    }

    @isTest
    static void testFieldSetAndRecordMethods() {
        Test.startTest();

        // Create a list of custom field info objects
        List<CustomFieldInfo> fieldInfos = new List<CustomFieldInfo>{
            new CustomFieldInfo('Name', 'Account Name'),
            new CustomFieldInfo('BillingCity', 'Billing City'),
            new CustomFieldInfo('Phone', 'Phone Number')
        };

        // Create a test AutoTable
        AutoTable table = new AutoTable();

        // Add fieldset - Create test Account records to use with addRecords
        List<Account> accounts = new List<Account>();
        for(Integer i = 1; i <= 3; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingCity = 'City ' + i,
                Phone = '555-000-' + String.valueOf(1000 + i)
            ));
        }
        insert accounts;

        // Manually add columns using our custom field info objects (since we can't directly implement FieldSetMember)
        for(CustomFieldInfo fieldInfo : fieldInfos) {
            table.addColumn(fieldInfo.label, fieldInfo.fieldPath);
        }

        // Verify columns were added correctly
        System.assertEquals(3, table.columns.size(), 'Should have 3 columns');
        System.assertEquals('Account Name', table.columns[0].title, 'First column should have correct title');
        System.assertEquals('Name', table.columns[0].dataKey, 'First column should have correct dataKey');
        System.assertEquals('Billing City', table.columns[1].title, 'Second column should have correct title');
        System.assertEquals('BillingCity', table.columns[1].dataKey, 'Second column should have correct dataKey');

        // Test addRecords method
        table.addRecords(accounts);

        // Verify records were added to the body
        System.assertEquals(3, table.body.size(), 'Should have 3 rows');

        // Verify content of rows
        System.assertEquals('Test Account 1', table.body[0].get('Name'), 'First row should have correct Name');
        System.assertEquals('City 2', table.body[1].get('BillingCity'), 'Second row should have correct BillingCity');
        System.assertEquals('555-000-1003', table.body[2].get('Phone'), 'Third row should have correct Phone');

        // Create a PDF and draw the table
        Pdf doc = new Pdf();
        doc.h1('FieldSet and Record Methods Test', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);
        table.options.startY = doc.getCurrentY() + 20;
        doc.autoTable(table.columns, table.body, table.options);

        // Save the PDF
        String filename = 'AutoTable_FieldSetAndRecords_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the fromSObjects method
     */
    /**
     * @description Tests the drawTable method
     */
    @isTest
    static void testDrawTable() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('Draw Table Test', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);

        // Create a table with the document reference
        AutoTable table = new AutoTable(doc);

        // Add columns
        AutoTable.Column col1 = new AutoTable.Column('ID', 'id', 100);
        AutoTable.Column col2 = new AutoTable.Column('Name', 'name', 200);
        List<AutoTable.Column> columns = new List<AutoTable.Column>{ col1, col2 };

        // Create body data
        List<Map<String, String>> bodyData = new List<Map<String, String>>{
            new Map<String, String>{ 'id' => '001', 'name' => 'Test Record 1' },
            new Map<String, String>{ 'id' => '002', 'name' => 'Test Record 2' }
        };

        // Configure options
        AutoTable.TableOptions options = new AutoTable.TableOptions();
        options.withStartY(doc.getCurrentY() + 20);
        options.theme = AutoTable.THEME_GRID;

        // Call the drawTable method directly
        Integer finalY = table.drawTable(columns, bodyData, options);

        // Verify the result
        System.assertNotEquals(null, finalY, 'Final Y position should not be null');
        System.assert(finalY > options.startY, 'Final Y position should be greater than start Y');

        // Save the PDF
        String filename = 'AutoTable_DrawTable_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Tests the exception conditions in the draw method
     */
    @isTest
    static void testDrawExceptions() {
        Test.startTest();

        // Test exception when pdf is null
        AutoTable table = new AutoTable();
        table.addColumn('ID', 'id');

        try {
            Integer y = table.draw();
            System.assert(false, 'Should have thrown an exception for null pdf');
        } catch (AutoTable.AutoTableException e) {
            System.assertEquals('PDF document not provided for table drawing', e.getMessage(), 'Exception message should match');
        }

        // Test exception when columns are empty
        Pdf doc = new Pdf();
        AutoTable tableNoColumns = new AutoTable(doc);

        try {
            Integer y = tableNoColumns.draw();
            System.assert(false, 'Should have thrown an exception for no columns');
        } catch (AutoTable.AutoTableException e) {
            System.assertEquals('No columns defined for table', e.getMessage(), 'Exception message should match');
        }

        Test.stopTest();
    }

    @isTest
    static void testFromSObjects() {
        Test.startTest();

        // Create a PDF document
        Pdf doc = new Pdf();
        doc.h1('SObject Table Test', PdfConstants.PAGE_MARGIN, PdfConstants.PAGE_MARGIN);

        // Create test Account records
        List<Account> accounts = new List<Account>();
        for(Integer i = 1; i <= 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingCity = 'City ' + i,
                Phone = '555-000-' + String.valueOf(1000 + i),
                AnnualRevenue = i * 100000
            ));
        }
        insert accounts;

        // Define fields and labels for the table
        List<String> fields = new List<String>{'Name', 'BillingCity', 'Phone', 'AnnualRevenue'};
        Map<String, String> fieldLabels = new Map<String, String>{
            'Name' => 'Account Name',
            'BillingCity' => 'City',
            'Phone' => 'Phone Number',
            'AnnualRevenue' => 'Annual Revenue'
        };

        // Save the initial Y position
        Integer initialY = doc.getCurrentY();

        // Call the fromSObjects method
        Integer finalY = AutoTable.fromSObjects(doc, accounts, fields, fieldLabels);

        // Verify the final Y position was returned and is greater than initial Y
        System.assert(finalY > initialY, 'Final Y position should be greater than initial Y');

        // Update the current Y position for reference
        doc.setCurrentY(finalY);

        // Save the PDF
        String filename = 'AutoTable_FromSObjects_' + DateTime.now().getTime();
        Id docId = doc.save(filename);

        // Verify document was created
        ContentVersion cv = [SELECT Id, Title, ContentSize FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assert(cv.ContentSize > 0, 'PDF document should not be empty');

        Test.stopTest();
    }

    /**
     * @description Creates test data for table tests
     * @return List<Map<String, String>> Sample data for testing
     */
    private static List<Map<String, String>> createTestData() {
        List<Map<String, String>> data = new List<Map<String, String>>();
        data.add(new Map<String, String>{
            'id' => '001',
            'name' => 'Product A',
            'price' => '$99.99',
            'qty' => '10'
        });
        data.add(new Map<String, String>{
            'id' => '002',
            'name' => 'Product B',
            'price' => '$149.99',
            'qty' => '5'
        });
        data.add(new Map<String, String>{
            'id' => '003',
            'name' => 'Product C',
            'price' => '$49.99',
            'qty' => '20'
        });
        return data;
    }

    /**
     * @description Creates test columns for table tests
     * @return List<AutoTable.Column> Sample columns for testing
     */
    private static List<AutoTable.Column> createTestColumns() {
        return new List<AutoTable.Column>{
            new AutoTable.Column('ID', 'id'),
            new AutoTable.Column('Product Name', 'name'),
            new AutoTable.Column('Price', 'price'),
            new AutoTable.Column('Quantity', 'qty')
        };
    }
}
