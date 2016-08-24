//
//  mappingModel.m
//  MMModel
//
//  Created by detu on 16/7/25.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "mappingModel.h"
#import "MMModel.h"
@implementation mappingModel
MMCode
+(NSDictionary *)mm_ReplacePropertyName{
    return @{
             @"name" :@"json.name",
             @"dict" :@"json.dict"
             
             };
}
@end

@implementation arrayPropertyModel
MMCode
+(NSDictionary *)mm_PropertyClassInArray{
    return @{
             @"models":[mappingModel class]  //models 这个属性里面装着  mappingModel 这个对象
             
             
             };
    
}
@end