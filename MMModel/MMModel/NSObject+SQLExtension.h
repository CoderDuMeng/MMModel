// iOS  杜蒙

#import <Foundation/Foundation.h>
@protocol MMModelProtocol <NSObject>
@optional
/*以下方法都是在model 类内部调用*/
/**处理替换的key  自定义属性名字*/
+(NSDictionary <NSString *, NSString *> *)mm_ReplacePropertyName;
/**自定义数组里面的key 对应那个类*/
+(NSDictionary <NSString *, Class>*)mm_PropertyClassInArray;
/**加白名单里面的属性是处理的没有加入的就是不处理的*/
+(NSArray <NSString *>*)mm_WhitePropertyList;
/**加入黑名单里面的属性是不用处理的没有加入的是处理的*/
+(NSArray <NSString *> *)mm_BlackPropertyList;
//新值替换旧值
- (id)mm_NewValueReplaceOldValueKey:(NSString *)property old:(id)oldValue;
@end

@interface NSObject (SQLExtension) <MMModelProtocol>
/**字典转模型*/
+(instancetype)mm_ModelObjectWithJSON:(id)json;
/**传入NSString 类型的json*/
+(instancetype)mm_ModelObjectWithStringJSON:(NSString *)json;
/**传入NSData 类型的json*/
+(instancetype)mm_ModelObjectWithDataJSON:(NSData *)json;
/**模型类 转字典*/
-(id)mm_JSONWithModel;
/*模型类  转String json*/
-(NSString *)mm_JSONStringWithModel;
/*模型类  转Data  json*/
-(NSData *)mm_JSONDataWithModel;

//编码
- (void)mm_ModelEncode:(NSCoder *)encode;
//解码
- (void)mm_ModelDecode:(NSCoder *)decode;


@end
#define MMCode \
-(instancetype)initWithCoder:(NSCoder *)aDecoder{\
if (self=[super init]) {\
[self mm_ModelDecode:aDecoder];\
}\
return self;\
}\
-(void)encodeWithCoder:(NSCoder *)aCoder{\
[self mm_ModelEncode:aCoder];\
}
