// iOS  杜蒙 

#import <Foundation/Foundation.h>
@interface NSObject (SQLExtension)

/**对象方法模型转字典*/
-(void)mm_ModelWithDictJson:(id)dict;

/**字典转模型*/
+(instancetype)mm_ModelObjectWithDictJson:(id)dict;
/**模型类 转字典*/
-(NSMutableDictionary *)mm_jsonWithModelObject;
//编码
- (void)mm_ModelEncode:(NSCoder *)encode;
//解码
- (void)mm_ModelDecode:(NSCoder *)decode;

/**检测是不是model类型 除Foundation框架的类型  no is model  yser is Foundation*/
- (BOOL)isNoClass;

@end

@interface NSObject (SQLFoundation)

/*以下方法都是在model 类内部调用*/

/**处理替换的key  自定义属性名字*/
+(NSDictionary *)mm_replacePropertyName;
/**自定义数组里面的key 对应那个类*/
+(NSDictionary *)mm_propertyClassInArray;
/**加白名单里面的属性是处理的没有加入的就是不处理的*/
+(NSArray *)mm_whitePropertyList;
/**加入黑名单里面的属性是不用处理的没有加入的是处理的*/
+(NSArray *)mm_blackPropertyList;


@end