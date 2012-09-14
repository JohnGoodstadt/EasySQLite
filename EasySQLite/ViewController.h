//
//  ViewController.h
//  EasySQLite
//
//  Created by john goodstadt on 14/09/2012.
//  Copyright (c) 2012 john goodstadt. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DBController,DataTable;

@interface ViewController : UIViewController <UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) DataTable* personTable;
@property (strong, nonatomic) DBController* db;

-(void)ReadeTableFromDB_Method1;
-(void)ReadeTableFromDB_Method2;
-(void)ReadeTableFromDB_Method3;

@end
