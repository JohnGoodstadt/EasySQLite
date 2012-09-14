//
//  DBController
//
//  Created by john goodstadt on 16/09/2012.
//  Copyright (c) 2012 John Goodstadt. All rights reserved.
//

#import "DBController.h"
#import "DataTable.h"

static DBController *sharedDatabaseController = nil;

//#define DB_NAME @"DataTable.sqlite" // Alter this to your SQLite db name

@interface DBController() // private functions
-(NSString *)createEditableCopyOfDatabaseIfNeeded;
-(NSString *)removeAndReCopyDatabase;
-(void)removeDatabase;
-(int)open;
-(void)close;
-(sqlite3_stmt*)prepare:(NSString*)query;
-(void)finalizeHandle:(sqlite3_stmt *)queryHandle;
-(void)begin;
-(void)commit;
@end

@implementation DBController
@synthesize dbpath,isOpen,database,rowsaffected,DBName=_DBName;

- (DBController*)init:(NSString*)thisDBName
{
    Class myClass = [self class];
    @synchronized(myClass)
	{
        if (sharedDatabaseController == nil)
		{
            if ((self = [super init]))
			{
                sharedDatabaseController = self;
				// Initialization code here.
                self.isOpen = NO;
                self.DBName = thisDBName;
                
                /*Important - this will copy the bundle DB to the writable documents if it does not exist in documents*/
                self.dbpath = [self createEditableCopyOfDatabaseIfNeeded];
                
                if(1==0) // to force a DB copy to documents run change to 1==1 and run once
                {
                    self.dbpath = [self removeAndReCopyDatabase];
                    NSAssert1(0, @"Dont go any futher - recopied DB",@"");
                }
                
                
                
                [sharedDatabaseController open];
                
                
            }
        }
    }
    return sharedDatabaseController;
}


#pragma mark -
#pragma mark Singleton access

+ (DBController *)sharedDatabaseController;
{
    @synchronized(self) 
	{
        if (sharedDatabaseController == nil) 
		{
            sharedDatabaseController = [[self alloc] init];            
        }
    }
    return sharedDatabaseController;
}
+ (DBController *)sharedDatabaseController:(NSString*)DBName
{
    @synchronized(self)
	{
        if (sharedDatabaseController == nil)
		{
            sharedDatabaseController = [[self alloc] init:DBName];
        }
    }
    return sharedDatabaseController;
}


#pragma mark - Low Level SQLite c routines
-(int)open
{
    
    if (sqlite3_open([self.dbpath UTF8String], &database) == SQLITE_OK)        
    {
        self.isOpen = YES;
        return SQLITE_OK;   
    }
    else
    {
         self.isOpen = NO;
        return -1;
    }
    
}
-(void)close{
    
     sqlite3_close(self.database);    
     self.isOpen = NO;
}

-(sqlite3_stmt*)prepare:(NSString*)query
{
    sqlite3_stmt *queryHandle;
   
    
    const char *sqlStatement = (const char *) [query UTF8String];
    
    if(sqlite3_prepare_v2(database, sqlStatement, -1, &queryHandle, NULL) != SQLITE_OK) 
    {
        int error = sqlite3_prepare_v2(database, sqlStatement, -1, &queryHandle, NULL);

        NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(database) );
        
        NSLog(@"Compiled Statement has error code:%i:%@",error,query);
    }

    return queryHandle;
}
-(void)finalizeHandle:(sqlite3_stmt *)queryHandle
{
    if (sqlite3_finalize(queryHandle) != SQLITE_OK)
        NSLog(@"finalize Statement has error");
    
}


#pragma mark - Wrapper Routines

- (int)ExecuteNonQuery:(NSString*)query
{
    
    if( self.isOpen == NO)
        return NSNotFound;
    
        
    self.rowsaffected = NSNotFound;  //assume error;
    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    if (sqlite3_step(queryHandle) != SQLITE_DONE) 
    {
         NSLog(@"ExecuteNonQuery has error");
         NSLog( @"Failed from sqlite3_step. Error is:  %s", sqlite3_errmsg(database) );
        
    }
    else
    {
        self.rowsaffected = sqlite3_changes(database);
    }
    
    [self finalizeHandle:queryHandle];
    
    return self.rowsaffected; // NSNotFound for error
}

- (int)ExecuteINSERT:(NSString*)query
{
    int returnValue = 0;
    
    if( self.isOpen == NO)
        return returnValue;
    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    if (sqlite3_step(queryHandle) != SQLITE_DONE) 
    {
        NSLog(@"ExecuteNonQuery has error");
        NSLog( @"Failed from sqlite3_step. Error is:  %s", sqlite3_errmsg(database) );
    }      
    [self finalizeHandle:queryHandle];
    
    
    returnValue = sqlite3_last_insert_rowid(database);
    
    
    return returnValue;
}


- (NSString*)ExecuteScalar:(NSString*)query
{
    NSString* returnValue = @"";
    
    if( self.isOpen == NO)
        return returnValue;
    
    NSString *sValue;
    int iValue = 0;
    float fValue = 0.0f;

    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    // only 1 row 1 column
    
    if(sqlite3_step(queryHandle) == SQLITE_ROW) 
    {
        // Read the data from the result row
        int columnCount = sqlite3_column_count(queryHandle);
        if (columnCount > 0)
        {
            NSString *colname = [NSString stringWithUTF8String:(char *)sqlite3_column_name(queryHandle, 0)];
            
            switch (sqlite3_column_type(queryHandle, 0))
            {
                case SQLITE_INTEGER:
                    iValue = sqlite3_column_int(queryHandle, 0);
                    NSLog(@"%@ %i",colname,iValue);                
                    returnValue = [NSString stringWithFormat:@"%i",iValue];
                    break;
                case SQLITE_TEXT:                    
                    sValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryHandle, 0)];
                    NSLog(@"%@ %@",colname,sValue);
                    returnValue = sValue;
                    break;                    
                case SQLITE_FLOAT:                    
                    fValue = sqlite3_column_double(queryHandle, 0);
                    NSLog(@"%@ %f",colname,fValue);
                    returnValue = [NSString stringWithFormat:@"%f",fValue];
                    break;
            }
        }
    }
    
    [self finalizeHandle:queryHandle];
    
    return returnValue;
}
- (int)ExecuteScalar:(NSString*)query asInt:(BOOL)asInt
{
    int returnValue = 0; // default return value
    
    if( self.isOpen == NO)
        return returnValue;

    int iValue = 0;
    
    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    // only 1 row 1 column
    
    if(sqlite3_step(queryHandle) == SQLITE_ROW) 
    {
        // Read the data from the result row
        int columnCount = sqlite3_column_count(queryHandle);
        if (columnCount > 0)
        {
            
            switch (sqlite3_column_type(queryHandle, 0))
            {
                case SQLITE_INTEGER:
                    iValue = sqlite3_column_int(queryHandle, 0);                                   
                    returnValue = iValue;
                    break;
                default:
                    NSLog(@"Error reading non integer column in routine expecting and integer DB column type.");
                    break;
            }
        }
    }
    
    [self finalizeHandle:queryHandle];
    
    return returnValue;
}
- (float)ExecuteScalar:(NSString*)query asFloat:(BOOL)asFloat
{
    float returnValue = 0.0; // default return value
    
    if( self.isOpen == NO)
        return returnValue;
    
   
    float fValue = 0.0f;
    
    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    // only 1 row 1 column of type float
    
    if(sqlite3_step(queryHandle) == SQLITE_ROW)
    {
        // Read the data from the result row
        int columnCount = sqlite3_column_count(queryHandle);
        if (columnCount > 0)
        {           
            
            switch (sqlite3_column_type(queryHandle, 0))
            {
                case SQLITE_FLOAT:
                    fValue = sqlite3_column_double(queryHandle, 0);
                    returnValue = fValue;
                    break;
                default:
                    NSLog(@"Error reading non integer column in routine expecting and integer DB column type.");
                    break;
                   
            }
        }
    }
    
    [self finalizeHandle:queryHandle];
    
    return returnValue;
}

// get vertical list from 1 column in table
- (NSArray*)ExecuteScalarArray:(NSString*)query
{
    
    if( self.isOpen == NO)
        return nil;
    
    int iValue = 0;
    NSString *sValue;
    float fValue = 0.0f;
    
    sqlite3_stmt *queryHandle  = [self prepare:query];
    
    NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:10];
    
    // only 1 row 1 column
    
    while(sqlite3_step(queryHandle) == SQLITE_ROW) 
    {
        
        switch (sqlite3_column_type(queryHandle, 0))
        {
            case SQLITE_INTEGER:
            {
                iValue = sqlite3_column_int(queryHandle, 0);
                NSNumber *oInt = [[NSNumber alloc] initWithInt:iValue];
                [list addObject:oInt];

                break;
            }
            case SQLITE_TEXT:
            {
                sValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryHandle, 0)];
                [list addObject:sValue];
                break;
            }
            case SQLITE_FLOAT:
            {
                fValue = sqlite3_column_double(queryHandle, 0);
                NSNumber *oFloat = [[NSNumber alloc] initWithFloat:fValue];
                [list addObject:oFloat];
                break;
            }
             
        }

        
        
                           
    }
    
    [self finalizeHandle:queryHandle];
    
    return list;
}
//return index of given column name 
-(int)indexFromColumnName:(sqlite3_stmt *)queryHandle withColname:(NSString*)colname;
{
    int returnValue = 0;
    
    int columnCount = sqlite3_column_count(queryHandle);
    
    for (int i = 0; i < columnCount; i++)
    {
       NSString *tablecol = [NSString stringWithUTF8String:(char *)sqlite3_column_name(queryHandle, i)];
        
       if ([tablecol caseInsensitiveCompare:colname] == NSOrderedSame)
       {
           returnValue = i;
           break;
       }
    }

    return returnValue;
}
- (NSString*)stringFromField:(sqlite3_stmt *)queryHandle withColname:(NSString*)colname
{
    int index = [self indexFromColumnName:queryHandle withColname:colname];             
    return  [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryHandle, index)];
    
}
- (int)intFromField:(sqlite3_stmt *)queryHandle withColname:(NSString*)colname 
{
    int index = [self indexFromColumnName:queryHandle withColname:colname];             
    return sqlite3_column_int(queryHandle, index);
    
}
- (float)floatFromField:(sqlite3_stmt *)queryHandle withColname:(NSString*)colname 
{
    int index = [self indexFromColumnName:queryHandle withColname:colname];             
    return sqlite3_column_double(queryHandle, index);
    
}


#pragma mark SQLite DB copy/delete handling

- (NSString *)createEditableCopyOfDatabaseIfNeeded
{
    
    if(!self.DBName)
    {
        NSLog(@"No DBName property defined. Please set  ");
        return @""; // No Path to return
    }
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
	
	//    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
//	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:_DBName];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:self.DBName];
  
    success = [fileManager fileExistsAtPath:writableDBPath];
      
	
	if (success) return writableDBPath;
	
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.DBName];
    
    /*!!! IF FAILS TO FIND BUNDLE SQLITE see http://forums.macrumors.com/showthread.php?t=826084 - Project properteis  Copy Bundle Resources group under Target > [Your App].*/
	
//    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:defaultDBPath];
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:defaultDBPath error:nil];
	if(fileAttributes != nil)
	{
		NSString *fileSize = [fileAttributes objectForKey:NSFileSize];
		NSLog(@"DB filesize %@",fileSize);
	}
	
    NSLog(@"Copying New DB.sqlite file to documents ");
	success = [fileManager  copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
	
	return writableDBPath;
}
- (void)removeDatabase
{
    if(!self.DBName)
    {
        NSLog(@"No DBName property defined. Please set  ");
        return; // No Path to return
    }
    
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
	
	//    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:self.DBName];
    
    
    success = [fileManager fileExistsAtPath:writableDBPath];
    
	if (success)
    {
        [[NSFileManager defaultManager] removeItemAtPath: writableDBPath error:&error];
    }

     NSAssert1(0, @"Dont go any futher - removed DB",@"");
}
//Just copy
- (NSString *)removeAndReCopyDatabase
{
    if(!self.DBName)
    {
        NSLog(@"No DBName property defined. Please set  ");
        return @""; // No Path to return
    }
    
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
	
	
	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:self.DBName];
    
    
    success = [fileManager fileExistsAtPath:writableDBPath];
    
	
	
	if (success)
    {
        [[NSFileManager defaultManager] removeItemAtPath: writableDBPath error:&error];
        //success = [fileManager fileExistsAtPath:writableDBPath];
    }
        
        
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.DBName];
		
	success = [fileManager  copyItemAtPath:defaultDBPath  toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
	
    //success = [fileManager fileExistsAtPath:writableDBPath];
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:writableDBPath error:nil];
	if(fileAttributes != nil)
	{
		NSString *fileSize = [fileAttributes objectForKey:NSFileSize];
		NSLog(@"DB filesize %@",fileSize);
	}

    
    // only used to copy DB to device
    // NSAssert1(0, @"Dont go any futher - copyied new database",@"");
    
	return writableDBPath;
}
-(void)begin
{
    sqlite3_exec(database, "BEGIN", 0, 0, 0); // Begin Transaction
}

-(void)commit
{
     sqlite3_exec(database, "COMMIT", 0, 0, 0); // Commit Transaction
}

- (DataTable*)ExecuteQuery:(NSString*)query
{
    
    if( self.isOpen == NO)
        return nil;
    
    
	int rowIndex = 0;
    // convert to c string 
    const char *sqlStatement = (const char *) [query UTF8String];
    sqlite3_stmt *queryHandle;
    NSString *sValue;
    int iValue = 0;
    float fValue = 0.0f;
    
    //NSMutableDictionary* row;
   // NSMutableArray* table = [[NSMutableArray alloc] initWithCapacity:10];
    
    NSMutableArray* columnNamesArray = [[NSMutableArray alloc] initWithCapacity:10]; // colum headers
    NSMutableArray* rowArray;
    NSMutableArray* rowsArray = [[NSMutableArray alloc] initWithCapacity:10]; // 10 rows
    
    if(sqlite3_prepare_v2(database, sqlStatement, -1, &queryHandle, NULL) == SQLITE_OK) 
    {
        int columnCount = sqlite3_column_count(queryHandle);
        
        while(sqlite3_step(queryHandle) == SQLITE_ROW) 
        {
           // row = [[NSMutableDictionary alloc] initWithCapacity:10]; // for this row
            rowArray = [[NSMutableArray alloc] initWithCapacity:10];
            
            for (int i = 0; i < columnCount; i++)
            {
                NSString *colname = [NSString stringWithUTF8String:(char *)sqlite3_column_name(queryHandle, i)];
                
                if(rowIndex==0) // first row
                {
                    [columnNamesArray addObject:colname];
                }
       
                     
                switch (sqlite3_column_type(queryHandle, i))
                {
                    case SQLITE_INTEGER:                      
                        iValue = sqlite3_column_int(queryHandle, i);
//                        NSLog(@"%@ %i",colname,iValue);
                        
                       // [row setObject:[NSNumber numberWithInt:iValue] forKey:colname];
                        
                        [rowArray addObject:[NSNumber numberWithInt:iValue]];
                        
                        break;
                    case SQLITE_TEXT:                      
                        sValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryHandle, i)];
//                        NSLog(@"%@ %@",colname,sValue);
                        
                       // [row setObject:sValue forKey:colname];
                         [rowArray addObject:sValue];
                        
                        break;                    
                    case SQLITE_FLOAT:
                        fValue = sqlite3_column_double(queryHandle, i);
//                        NSLog(@"%@ %f",colname,fValue);
                       
                        // [row setObject:[NSNumber numberWithFloat:fValue] forKey:colname];
                         [rowArray addObject:[NSNumber numberWithFloat:fValue]];
                        
                        break;
                }                
                
            }   
        
            rowIndex++;
           // [table addObject:row];
            [rowsArray addObject:rowArray];
            
        }
        
    }
    else 
    {
        NSLog(@"Compiled Statement has error:%@",query);
        NSLog(@"%s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(queryHandle);
    
    
    DataTable* table = [[DataTable alloc] init];
    table.rows = rowsArray;
    table.columns = columnNamesArray;
 
    
    return table;
    
  }


@end
