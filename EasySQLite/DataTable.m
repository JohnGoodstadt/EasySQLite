//
//  Table.m
//  tryDataTable
//
//  Created by john goodstadt on 16/09/2012.
//  Copyright (c) 2012 John Goodstadt. All rights reserved.
//

#import "DataTable.h"

@implementation NSNumber (toString)
-(NSString *)toString
{
    return [NSString stringWithFormat:@"%@",self] ;
}
@end

@implementation DataTable
@synthesize rows=_rows,columns=_columns;

-(int)colIndex:(NSString*)colname
{
    int returnValue = 0;
    
    // could use dictionary for quicker lookup
    int colindex = 0;
    for (NSString* name in _columns)
    {
        if([name caseInsensitiveCompare:colname] == NSOrderedSame)
        {
            returnValue = colindex;
            break;
        }
        colindex++;
    }
    
    
    return returnValue;
    
}
-(NSString*)getValueFromRow:(int)rowindex forColumnName:(NSString*)colname
{
    // could use dictionary for quicker lookup
    int colindex = 0;
    for (NSString* name in _columns)
    {
        if([name caseInsensitiveCompare:colname] == NSOrderedSame)
            break;
        
        colindex++;
    }

    
    return [self getValueFromRow:rowindex forColumn:colindex];
    
}
-(NSString*)getValueFromRow:(int)rowindex forColumn:(int)colindex
{
    NSString* returnValue = @"";
    
    if(_rows)
    {
        if(rowindex < _rows.count)
        {
            NSArray* thisrow = [_rows objectAtIndex:rowindex];
            if(colindex < thisrow.count)
            {
                id thiscolumn = [thisrow objectAtIndex:colindex];
                
                if([thiscolumn isKindOfClass:[NSNumber class]])
                {
                    CFNumberType numberType = CFNumberGetType((__bridge CFNumberRef)thiscolumn);
                    if(numberType == kCFNumberFloatType)
                    {
                        NSLog(@" float col:%f",[thiscolumn floatValue]); 
                        returnValue = [NSString stringWithFormat:@"%@",thiscolumn];
                    }
                    else {
                        NSLog(@" int col:%i",[thiscolumn intValue]);  
                        returnValue = [NSString stringWithFormat:@"%@",thiscolumn];
                    }
                    
                }
                else if([thiscolumn isKindOfClass:[NSString class]])
                {
                    NSLog(@" String col:%@",thiscolumn); 
                    returnValue = thiscolumn;
                }
                /*
                 else Non supported Type
                 */

                
                
                
            }
        }
        else {
            //error
        }
    }
    else {
        //error
    }
    return returnValue;
}

@end
