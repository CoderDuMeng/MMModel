//
//  jsonModel.m
//  MMModelExample
//
//  Created by detu on 16/7/19.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "jsonModel.h"
#import "MMModel.h"
@implementation jsonModel
MMCode  //归档是需要这个宏  
@end
@implementation ObjectModel
@end


@implementation blackModel
//加入黑名单的属性 所有属性里面 只是不处理黑名单的属性
MMCode
+(NSArray *)mm_BlackPropertyList{
    return @[@"appName",@"appType"];
}
@end

@implementation whiteModel
MMCode
//加入白名单的属性 所有属性里面 只是处理白名单里面的属性
+(NSArray *)mm_WhitePropertyList{
    return @[@"appName",@"appType"];
}
@end
