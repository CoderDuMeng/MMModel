# MMModel
### 使用简单的数据转模型 模型转数据 
##  字典转模型这种类型的框架处理速度快的重要一点其实就是缓存节省时间取某一个值 和类型匹配
- **_classPropertyValues 字典** 缓存属性模型 
- **_classPropertyReplaceValues   字典** 缓存替换的属性Name 
- **_classPropertyBlackListValues 字典** 缓存黑名单属性
- **_classPropertyWhiteListValues 字典** 缓存白名单属性 
- **_classPropertyKeyMoresCounts  字典** 缓存多级映射的key
- **_classPropertyClassInArrays   字典** 缓存数组字典Class
  
## 功能 
- **字典转模型** 
- **模型转字典**  
- **黑名单处理** 加在黑名单里面的属性 转模型 模型转字典 归档 都会处理
- **白名单处理** 加在白名单里面的属性 转模型 模型转字典 归档 都会处理
- **归档** 
- **属性替换**          
 
## Demo里面的模型类 

jsonModel
```objc
@interface jsonModel : NSObject
@property (assign , nonatomic) int age;
@property (copy , nonatomic) NSString *name;
@property (copy , nonatomic) NSString *source;
@property (assign , nonatomic) float price;
@property (assign , nonatomic) BOOL is;
@end
```
-- **ObjectModel** 
```objc
@interface ObjectModel : NSObject

@property (strong , nonatomic)  jsonModel *json;

@property (strong , nonatomic)  jsonModel *json1;

@end

```
blackModel 
```objc 
@interface blackModel : NSObject
@property (copy, nonatomic)NSString *appName;
@property (copy, nonatomic)NSString *appType;
@property (copy, nonatomic)NSString *appSize;
@property (copy, nonatomic)NSString *appColor;
@end
@implementation blackModel
//加入黑名单的属性 所有属性里面 只是不处理黑名单的属性

+(NSArray *)mm_blackPropertyList{
return @[@"appName",@"appType"];
}
@end
```

whiteModel
```objc 
@interface whiteModel : NSObject
@property (copy, nonatomic)NSString *appName;
@property (copy, nonatomic)NSString *appType;
@property (copy, nonatomic)NSString *appSize;
@property (copy, nonatomic)NSString *appColor;
@end
@implementation whiteModel
//加入白名单的属性 所有属性里面 只是处理白名单里面的属性
+(NSArray *)mm_whitePropertyList{
return @[@"appName",@"appType"];
}
@end

```

mappingModel 
```objc 
@interface mappingModel : NSObject
@property (strong , nonatomic) NSString *name;
@property (strong , nonatomic) NSDictionary *dict;
@end
@implementation mappingModel
+(NSDictionary *)mm_replacePropertyName{
return @{
@"name" :@"json.name",
@"dict" :@"json.dict"

};
}
@end
````
arrayPropertyModel
```objc 
@interface arrayPropertyModel : NSObject

@property (strong , nonatomic) NSArray *models;

@end
@implementation arrayPropertyModel
+(NSDictionary *)mm_propertyClassInArray{
return @{
@"models":[mappingModel class]  //models 这个属性里面装着  mappingModel 这个对象
};
}
@end
````


## 简单的json转模型  
```objc
            NSDictionary *json = @{
            @"age":@"100",
            @"name" :@"ios",
            @"source":@"zhongguo",
            @"price" :@"13.1",
            @"is" :@YES
            };

            jsonModel *model = [jsonModel mm_ModelObjectWithDictJson:json];
            NSLog(@"age:%zi  name:%@ source:%@ prcie:%2f is:%zi",model.age,model.name,model.source,model.price,model.is);

            NSLog(@"json -> model  %@",model.mm_jsonWithModelObject);

```
## 多级映射取值
```objc
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

            NSLog(@"json->model:%@",model.mm_jsonWithModelObject);

```
##  模型类型作为属性
```objc
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


            NSLog(@"json->model:%@",model.mm_jsonWithModelObject);

```
##   数组字典转数组模型
```objc
            NSDictionary *json = @{
            @"models" :@[@
                         {@"name":@"dumeng",
                         @"dict":@{@"age":@"100",
                        @"name":@"dict" 
                       }
                     },
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

            NSLog(@"json: %@",model.mm_jsonWithModelObject);
```
## 黑名单 
```objc
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

        NSLog(@"blackJson:%@",model.mm_jsonWithModelObject);
```
##  白名单  

  ```objc
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

        NSLog(@"whiteJson:%@",model.mm_jsonWithModelObject);
   ```
##  归档  
```objc
         在接档和归档的方法里面实现分别实现这个两行
           
        -(instancetype)initWithCoder:(NSCoder *)aDecoder{
        if (self=[super  init]) {
        [self mm_ModelDecode:aDecoder];
        }
        return self;
        }
        -(void)encodeWithCoder:(NSCoder *)aCoder{
        [self mm_ModelEncode:aCoder];

        }

```