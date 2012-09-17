# EasySQLite #


This sample application demonstrates how to easily get your data from your SQLite DB.

Use this file in your own projects as you see fit.
Please email me at john@goodstadt.me.uk for any problems, fixes, addition or thanks.


Example:

```obj-c
DataTable* table = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];
for (NSArray* row in table.rows)
{
    NSString* firstname = row[0]; // in column order 0 is first column in query above
    NSString* lastname = row[1];
    NSNumber* age = row[2]; // sqlite ints and floats arrive as NSNumbers
    NSNumber* salary = row[3];
}
```

# Other useful commands:

```obj-c
//Scalar 1 result returned
int personCount = [_db  ExecuteScalar:@"SELECT count(*) FROM person" asInt:YES];

// UPDATE command
int rowsaffected = [_db  ExecuteNonQuery:@"UPDATE person set salary = 20000 WHERE lastname = 'smith'"];

// INSERT - returning New Auto Increment ID
int DBID = [_db  ExecuteINSERT:@"INSERT INTO person(firstname,lastname,age,salary) VALUES('sue','peterson',32,15123.39)"];


//Delete - returning how many rows affteced by delete
int rowsaffected = [_db  ExecuteNonQuery:@"DELETE FROM person WHERE lastname = 'smith'"];
```

================================================================================
# Instructions to run sample:

open EasySQLite.xcodeproj and run.
A Demo DB will be read and echoed to the Log window and a UITableview will display each row

================================================================================
# Instructions to add to your own project:

Copy Database group to your project - 4 files (DataTable.h,DataTable.m,DBController.h,DBController.m)

Add an iVar viewController.h that will access the DB:

```obj-c
@property (strong, nonatomic) DBController* db;
```

Add these lines to the viewController.m that will access the DB:

```obj-c
#import "DBController.h"
#import "DataTable.h"

//synthesize the iVar
@synthesize db=_db;

//Set up DB connection
self.db = [DBController sharedDatabaseController:@"DataTable.sqlite"]; // Change DB name to your name here


//Execute Command
DataTable* table = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];

// list out values

for (NSArray* row in table.rows)
{
    
    NSString* firstname = row[0]; // in column order 0 is first column in query above
    NSString* lastname = row[1];
    NSNumber* age = row[2]; // sqlite ints and floats arrive as NSNumbers
    NSNumber* salary = row[3];
    
    
    NSLog(@"row:%i %@ %@ %@ %@",
          [table.rows indexOfObject:row]+1, /*zero based*/
          firstname,
          lastname,
          age,
          salary);
    
}
```

Last Revision:
Version 1.0, 2012-09-14
Build Requirements:
iOS SDK 5 - Phone device
Runtime Requirements:
iOS 5 or later
**XCode 4.5 IOS 6.0** - for new, easier, array Syntax.
If you use pre XCode 4.5 (IOS 5) change row[0] syntax to [row objectAtIndex:0]
