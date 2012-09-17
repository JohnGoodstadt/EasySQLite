//
//  ViewController.m
//  EasySQLite
//
//  Created by john goodstadt on 14/09/2012.
//  Copyright (c) 2012 john goodstadt. All rights reserved.
//

#import "ViewController.h"
#import "DBController.h"
#import "DataTable.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize tableview=_tableview;
@synthesize personTable=_personTable;
@synthesize db=_db;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // setup connection to DB in iVar
    self.db = [DBController sharedDatabaseController:@"DataTable.sqlite"];
    
    [self ReadeTableFromDB_Method1];
    [self ReadeTableFromDB_Method2];
    [self ReadeTableFromDB_Method3];
    [self ReadeTableFromDB_Method4];
    [self otherSQLCommands];
    
    [self setupTableviewData];
}
- (void)viewDidUnload {
    [self setTableview:nil];
    [super viewDidUnload];
}

#pragma mark - Helper Functions
-(void)setupTableviewData
{
    
    self.personTable = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];
    
    [_tableview reloadData];
    
    
}
/*
 show loop syntax for( ...
 */
-(void)ReadeTableFromDB_Method1
{
          
    NSLog(@"Reading table person. - method 1.");
    
    DataTable* table = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];
    
    for (NSArray* row in table.rows)
    {
        for(NSString* column in table.columns)
        {
            NSLog(@"row:%i %@=%@",
                  [table.rows indexOfObject:row]+1, /*zero based*/
                  column,
                  row[[table colIndex:column]]);
        }
    }
    
    
}
/*
 show syntax table.row[row]
 */
-(void)ReadeTableFromDB_Method2
{
      
    NSLog(@"Reading table person - method 2.");
    
    DataTable* table = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];
    
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
    
    
}
/*
 show syntax table.rows[row][column] - index introduced first use in XCode 4.5
 */
-(void)ReadeTableFromDB_Method3
{
    
    NSLog(@"Reading table person - method 3.");
    
    DataTable* table = [_db  ExecuteQuery:@"SELECT firstname , lastname , age , salary FROM person"];
    
    NSString* firstname =   table.rows[1][0]; // row 2 col 1 - zero based - if earlier than xcode 4.5 change to [table.rows[1] objectAtIndex:0]
    NSString* lastname =    table.rows[1][1]; // row 2 col 2
    NSNumber* age =         table.rows[1][2]; // row 2 col 3
    NSNumber* salary =      table.rows[1][3]; // row 2 col 4

    NSLog(@"row:2 %@ %@ %@ %@",
          firstname,
          lastname,
          age,
          salary);
    
       
    
}
/*
 show syntax table.row[colindex]
 */
-(void)ReadeTableFromDB_Method4
{
    
    NSLog(@"Reading table person - method 4.");
    
    DataTable* table = [_db  ExecuteQuery:@"SELECT * FROM person"];
    
    
    int indexOfColumnAge = [table colIndex:@"age"];
    
    for (NSArray* row in table.rows)
    {
        NSNumber* age = row[indexOfColumnAge]; // sqlite ints and floats arrive as NSNumbers
        
        NSLog(@"row:%i age:%@",
              [table.rows indexOfObject:row]+1, /*zero based*/
              age);
        
    }
    
    
}


-(void)otherSQLCommands
{
    /* get 1 vertical column from each row into an array */
    
    NSLog(@"Reading table person - vertical slice of salaries descending order");
    NSArray* salaries = [_db  ExecuteScalarArray:@"SELECT salary FROM person ORDER BY 1 desc"];
    
    for (NSNumber* salary in salaries)
        NSLog(@"salary:%@",salary);
    
    
    
    NSLog(@"Reading table person - return 1 value back - integer");
    int personCount = [_db  ExecuteScalar:@"SELECT count(*) FROM person" asInt:YES];
    NSLog(@"count of rows:%i",personCount);
    
    
    
    
    NSLog(@"Reading table person - sumn all salaries - integer");
    float salarySum = [_db  ExecuteScalar:@"SELECT SUM(salary) FROM person" asFloat:YES];
    NSLog(@"Sum of all Salaries:%f",salarySum);
    
    
    NSLog(@"Executing UPDATE command");
    int rowsaffected = [_db  ExecuteNonQuery:@"UPDATE person set salary = 20000 WHERE lastname = 'smith'"];
    NSLog(@"updates %i rows",rowsaffected);
    
    NSLog(@"Executing INSERT command");
    int DBID = [_db  ExecuteINSERT:@"INSERT INTO person(firstname,lastname,age,salary) VALUES('sue','peterson',32,15123.39)"];
    NSLog(@"new DBID %i ",DBID);
    
    
    salarySum = [_db  ExecuteScalar:@"SELECT SUM(salary) FROM person" asFloat:YES];
    NSLog(@"Sum of all Salaries:%f",salarySum);
    
    NSLog(@"Executing DELETE command");
    rowsaffected = [_db  ExecuteNonQuery:@"DELETE FROM person WHERE lastname = 'peterson'"];
    NSLog(@"deleted %i row(s)",rowsaffected);
    
    
}



#pragma mark - TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _personTable.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] ;
        
        
    }
    
    NSArray* row= _personTable.rows[indexPath.row];
    
    cell.textLabel.text = row[[_personTable colIndex:@"lastname"]];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ %@ %@",row[[_personTable colIndex:@"firstname"]],row[[_personTable colIndex:@"lastname"]],row[[_personTable colIndex:@"age"]],row[[_personTable colIndex:@"salary"]]];
    
    
    return cell;
    
    
    
}

@end
