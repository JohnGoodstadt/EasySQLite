//
//  DBController
//
//  Created by john goodstadt on 16/09/2012.
//  Copyright (c) 2012 John Goodstadt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SQLite3.h>

@class DataTable;

@interface DBController : NSObject
{
    NSString* DBName;
    NSString* dbpath;
    sqlite3*  database;
    BOOL isOpen;
    
    int rowsaffected;
}
@property (atomic,retain)  NSString* DBName;
@property (atomic,retain)  NSString* dbpath;
@property (atomic,assign)  sqlite3*  database;
@property (atomic,assign)  BOOL isOpen;
@property (atomic,assign)  int rowsaffected;


// Singleton access
+ (DBController *)sharedDatabaseController;
+ (DBController *)sharedDatabaseController:(NSString*)DBName; // pass in DBName once in program
- (DBController*)init:(NSString*)DBName;

-(DataTable*)ExecuteQuery:(NSString*)query; //execute a SELECT - return in a 2 dimensional Array of columns and rows

-(int)ExecuteNonQuery:(NSString*)query;     // execute an UPDATE or DELETE Quary with this
-(int)ExecuteINSERT:(NSString*)query;       // execute an INSERT query - the new Auto increment DBID will be returned
-(NSString*)ExecuteScalar:(NSString*)query; //execute a SELECT the first column and row will be returned as a string
-(int)ExecuteScalar:(NSString*)query asInt:(BOOL)asInt;         //execute a SELECT the first column will be returned in an array of ints (NSNumbers)
-(float)ExecuteScalar:(NSString*)query asFloat:(BOOL)asFloat;   //execute a SELECT the first column will be returned in an array of floats (NSNumbers)
-(NSArray*)ExecuteScalarArray:(NSString*)query;                 //execute a SELECT the first column will be returned in an array of strings

-(int)indexFromColumnName:(sqlite3_stmt *)queryHandle withColname:(NSString*)colname;// translate a column name into a column index


@end
