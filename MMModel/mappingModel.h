//
//  mappingModel.h
//  MMModel
//
//  Created by detu on 16/7/25.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface mappingModel : NSObject
@property (strong , nonatomic) NSString *name;
@property (strong , nonatomic) NSDictionary *dict;
@end


@interface arrayPropertyModel : NSObject

@property (strong , nonatomic) NSArray *models;


@end
