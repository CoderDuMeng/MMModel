//
//  ViewController.m
//  MMModel
//
//  Created by detu on 16/7/25.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "ViewController.h"

#import "MMModel.h" 




#import "jsonModel.h"
#import "mappingModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self modelWithJson];  //<< 简单的json转模型
    [self Multistagemapping]; // <<多级映射取值
    [self objectisProertyName]; //<<模型类型作为属性
    [self arrayProertyWithModel]; //<<数组字典转数组模型
    [self propertyBlackList];   //<<黑名单
    [self propertyWhiteList];   //<<白名单
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//字典转模型  json -> model
//模型转字典  model-> json
- (void)modelWithJson{
    
    NSDictionary *json = @{
                           @"age":@"100",
                           @"name" :@"ios",
                           @"source":@"zhongguo",
                           @"price" :@"13.1",
                           @"is" :@YES
                           };
    
    
    
    jsonModel *model = [jsonModel mm_ModelObjectWithDictJson:json];
    
    
    NSLog(@"age:%zi  name:%@ source:%@ prcie:%2f is:%zi",model.age,model.name,model.source,model.price,model.is);
    
    
    NSLog(@"json -> model  %@",model.mm_JsonWithModelObject);
    
}

//多级映射取值  json ->model
//多级映射转json  model ->
- (void)Multistagemapping{
    
    
    NSDictionary *json = @{
                           @"json":@{
                                   @"name" :@"dumeng",
                                   @"dict" : @{
                                       
                                           @"age" :@"1",
                                        
                                       }
                                   
                                   },
                          
                           };
    
    
    //解释：  mappingModel 里面的name取 字典里面的一个key是字典里面的值 取最里面字典的值 多级映射
    /*  
     需要在model类里面实现这样的代码  
     +(NSDictionary *)mm_replacePropertyName{
     return @{
        @"name" :@"json.name",
        @"dict" :@"json.dict"
     
     };
     
    }
     */
    mappingModel *model = [mappingModel mm_ModelObjectWithDictJson:json];
    
    
    NSLog(@"name:%@  dict:%@",model.name,model.dict);
    
    NSLog(@"json->model:%@",model.mm_JsonWithModelObject);
    
   
    
    
}

//模型属性转json
- (void)objectisProertyName{

    NSDictionary *json = @{
                           @"json":@{
                                   @"age":@"100",
                                   @"name" :@"ios",
                                   @"source":@"zhongguo",
                                   @"price" :@"13.1",
                                   @"is" :@YES
                                   },
                           
                           
                           @"json1":@{ @"age":@"200",
                                       @"name" :@"iosJson",
                                       @"source":@"zhongguoNIhao",
                                       @"price" :@"32.3",
                                       @"is" :@YES
                                       
                                       }
                           };
    //模型作为属性
    ObjectModel *model = [ObjectModel mm_ModelObjectWithDictJson:json];
    
    NSLog(@"%zi  %@",model.json.age, model.json1.name);

    
    NSLog(@"json->model:%@",model.mm_JsonWithModelObject);
    
  
    
    
}

//数组作为属性里面元素转成模型
- (void)arrayProertyWithModel{
    
    NSDictionary *json = @{
                           @"models" :@[
                                          @{    @"name":@"dumeng",
                                                @"dict":@{@"age":@"100",
                                                @"name":@"dict"
                                             
                                                }
                                            }
                                          ,
                                                @{@"name":@"dumeng",
                                                @"dict":@{@"age":@"100",
                                                @"name":@"dict"
                                               
                                               }
                                            }
                                          ,
                                               @{@"name":@"dumeng",
                                               @"dict":@{@"age":@"100",
                                               @"name":@"dict"
                                               
                                               }
                                             }
                                          ]
                           
                                       };
    
    
    
    arrayPropertyModel *model = [arrayPropertyModel mm_ModelObjectWithDictJson:json];
    
    NSLog(@"models:%@",model.models);
    
    NSLog(@"json: %@",model.mm_JsonWithModelObject);
    
   
}


//黑名单
- (void)propertyBlackList{
   
    NSDictionary *json = @{@"appName":@"ios",
                           @"appType":@"VR",
                           @"appSize":@"100M",
                           @"appColor":@"white"
                           
                           };
    
    /*
     
     //加入黑名单的属性 所有属性里面 只是不处理黑名单的属性
     
     +(NSArray *)mm_blackPropertyList{
       
       return @[@"appName",@"appType"];
     
     }
     */
    blackModel *model = [blackModel mm_ModelObjectWithDictJson:json];
    
    NSLog(@"blackJson:%@",model.mm_JsonWithModelObject);
    
    
    
}

//白名单
- (void)propertyWhiteList{
    
    NSDictionary *json = @{@"appName":@"ios",
                           @"appType":@"VR",
                           @"appSize":@"100M",
                           @"appColor":@"white"
                           
                           };
    
    /*
     //加入白名单的属性 所有属性里面 只是处理白名单里面的属性
     +(NSArray *)mm_whitePropertyList{
       
       return @[@"appName",@"appType"];
     
     }
     
     */
    
    whiteModel *model = [whiteModel mm_ModelObjectWithDictJson:json];
    
    NSLog(@"whiteJson:%@",model.mm_JsonWithModelObject);
  
    
}



@end
