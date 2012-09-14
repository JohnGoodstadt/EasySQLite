//
//  Table.h
//  tryDataTable
//
//  Created by john goodstadt on 16/09/2012.
//  Copyright (c) 2012 John Goodstadt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSNumber (toString)
-(NSString *)toString;
@end

@interface DataTable : NSObject
{
    NSArray* columns;
    NSArray* rows;
     
}
@property (atomic,retain)   NSArray* columns;
@property (atomic,retain)   NSArray* rows;

-(int)colIndex:(NSString*)colname;
@end
