//
//  jsonModel.h
//  MMModelExample
//
//  Created by detu on 16/7/19.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface jsonModel : NSObject
@property (assign , nonatomic) int age;
@property (copy , nonatomic) NSString *name;
@property (copy , nonatomic) NSString *source;
@property (assign , nonatomic) float price;
@property (assign , nonatomic) BOOL is;
@end


@interface ObjectModel : NSObject

@property (strong , nonatomic)  jsonModel *json;

@property (strong , nonatomic)  jsonModel *json1;

@end


@interface blackModel : NSObject
@property (copy, nonatomic)NSString *appName;
@property (copy, nonatomic)NSString *appType;
@property (copy, nonatomic)NSString *appSize;
@property (copy, nonatomic)NSString *appColor;
@end
@interface whiteModel : NSObject
@property (copy, nonatomic)NSString *appName;
@property (copy, nonatomic)NSString *appType;
@property (copy, nonatomic)NSString *appSize;
@property (copy, nonatomic)NSString *appColor;
@end

