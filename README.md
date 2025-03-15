# ApexPdf
Native Apex re-implementation of jsPDF API using the Salesforce Apex language.
This implementation is an incomplete port of jsPDF to Apex.

inspiration: https://github.com/parallax/jsPDF

API docs that guide this project: https://raw.githack.com/MrRio/jsPDF/master/docs/index.html

# Usage
This repo is intended to be included in a larger project as a git submodule.  
Example, when you have deployed the Apex code in this repo, the following execute anon should produce a PDF file in **Files**
```
List<Account> accounts = [SELECT Id, Name, Phone, Industry, Type,
                            BillingStreet, BillingCity, BillingState,
                            BillingPostalCode, BillingCountry, Owner.Name, CreatedDate
                            FROM Account LIMIT 10];

// Create the table data structure - must be Map<String, String> for autoTable
List<Map<String, String>> tableData = new List<Map<String, String>>();

// Add account data rows
for (Account acc : accounts) {
    Map<String, String> dataRow = new Map<String, String>();
    dataRow.put('Name', acc.Name != null ? acc.Name : '');
    dataRow.put('Owner', acc.Owner.Name != null ? acc.Owner.Name : '');
    dataRow.put('CreatedDate', acc.CreatedDate != null ? acc.CreatedDate.format() : '');
    tableData.add(dataRow);
}

// Create PDF
Pdf doc = new Pdf();
doc.text('Account Report', 36, 14);
doc.text('Generated on ' + System.now().format(), 36, 30);

// Define columns
List<AutoTable.Column> columns = new List<AutoTable.Column>();
columns.add(new AutoTable.Column('Name', 'Name'));
columns.add(new AutoTable.Column('Owner', 'Owner'));
columns.add(new AutoTable.Column('CreatedDate', 'CreatedDate'));

// Configure options for striped theme
AutoTable.TableOptions options = new AutoTable.TableOptions();
options.theme = 'STRIPED';
options.startY = doc.getCurrentY() + 20;

// Customize alternate row color for better visibility
options.alternateRowStyles = new Map<String, Object>{
    'fillColor' => 'EAEAEA'  // Slightly darker gray for better contrast
};

// Generate the table output
doc.autoTable(columns, tableData, options);

// Save and return the PDF ID
doc.save('Account_Report_' + System.now().format('yyyy-MM-dd'));
```
