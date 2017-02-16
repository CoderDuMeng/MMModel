//
//  NSObject+SQLExtension.m
//  SQliteExample



#import "NSObject+SQLExtension.h"
#import "SQLPropertyType.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface SQPropertyMeta : NSObject
{
    @package
    Class      _ClassType;
    BOOL       _isFoundation;
    NSString   *_PropertyName;
    type_      _TypeCode;
    typeFoundation_  _TypeFoundation;
    SEL        _setSelecor;
}

-(instancetype)initWithIvar:(Ivar )ivar class:(Class )c;
@end
@implementation SQPropertyMeta
-(instancetype)initWithIvar:(Ivar)ivar class:(__unsafe_unretained Class)c{
    if (self= [super init]) {
        const char  *charType =  ivar_getTypeEncoding(ivar);
        //属性类型
        NSMutableString *type  = [NSMutableString  stringWithUTF8String:charType];
        //对象类型
        if ([type hasPrefix:@"@"]) {
            self->_ClassType = NSClassFromString([type substringWithRange:NSMakeRange(2, type.length-3)]);
            typeFoundation_ isFoundation = PropertyFoundtaionType(_ClassType);
            self->_TypeFoundation = isFoundation;
            self->_isFoundation = YES;
            
        }else{
            self->_TypeCode = PropertyNumberType(charType);
        }
        //属性名字
        NSMutableString *key  = [NSMutableString stringWithUTF8String:ivar_getName(ivar)];
        [key replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        self->_PropertyName = [key copy];
        
        [[self->_PropertyName substringToIndex:1] uppercaseString];
        
        NSString *set = [NSString stringWithFormat:@"set%@%@:",[[_PropertyName substringToIndex:1] uppercaseString],[self->_PropertyName substringWithRange:NSMakeRange(1, self->_PropertyName.length - 1)]];
        
        self->_setSelecor = NSSelectorFromString(set);
        
        
    }
    return self;
}

@end


@interface SQPropertyMetaInfo : NSObject
{
    @package
    SEL _set;  //<< set 方法
    NSString *_name; //<< 属性名字
    NSString *_replaceName;//<< 替换的属性名字
    NSArray  *_replaceMoreNames;//<<多级映射的keys
    type_ _numberType;//<<基本数据类型
    typeFoundation_ _isNSType; //<<NS 系列的对象类型
    Class _mappingInArray;//<< 内映射Class
    Class _propertyClass;//<< 属性是对象类型
    BOOL  _isNS;//<<是否是对象
}
-(instancetype)initWithMetaInfoIvar:(Ivar)ivar Class:(Class )c;
@end
@implementation SQPropertyMetaInfo
-(instancetype)initWithMetaInfoIvar:(Ivar)ivar Class:(Class )c{
    if (self=[super init]) {
        SQPropertyMeta *meta = [[SQPropertyMeta alloc] initWithIvar:ivar class:c];
        self->_name = meta->_PropertyName;
        self->_numberType = meta->_TypeCode;
        self->_isNSType   = meta->_TypeFoundation;
        Class cl          = meta->_ClassType;
        if (cl) {
            self->_propertyClass = cl;
            self->_isNS = YES;
        }
        SEL set_ = meta->_setSelecor;
        if ([c instancesRespondToSelector:set_]) {
            self->_set = set_;
        }else{
            return nil;
        }
    }
    return self;
}
@end
@interface SQClassMeta : NSObject
{
    @package
    /*
     调用此方法返回的映射数组里面的映射成那个类型 (或者是字典里面的key 也是字典的时候)
     +(NSDictionary <NSString *, Class>*)mm_PropertyClassInArray{
     
     return @{
     @"key" :[NSObject class]
     
     };
     }
     */
    NSDictionary   <NSString *,Class >*_ClassInArrays;
    NSMutableArray <NSString*>*_PropertyNames;//<<属性的名字
    NSMutableArray <SQPropertyMetaInfo *>*_PropertyMetas;//<<没有参与替换属性名字
    NSMutableArray <SQPropertyMetaInfo *>*_MappingMorePropertyMetas; //<< 参与多级映射
    NSMutableArray <SQPropertyMetaInfo *>*_MappingPropertyMetas; //<<参与替换属性名字
    
    BOOL _isNewValueReplaceOldValue; //<< 是否执行了新值替换旧值
    
}
-(instancetype)initWithClass:(Class )c;
+(instancetype)initWithMetaClass:(Class )c;
@end
@implementation SQClassMeta
-(instancetype)initWithClass:(Class)c{
    if (self=[super init]) {
        if(PropertyFoundtaionType(c)!= _typeObject) return nil;
        //黑名单
        NSArray *blackList = nil;
        if ([c respondsToSelector:@selector(mm_BlackPropertyList)]) {
            NSArray *blackLists = [c mm_BlackPropertyList];
            if (blackLists) {
                blackList = blackLists;
            }
        }
        //白名单
        NSArray *whileList = nil;
        if ([c respondsToSelector:@selector(mm_WhitePropertyList)]) {
            NSArray *whileLists = [c mm_WhitePropertyList];
            if (whileLists) {
                whileList = whileLists;
            }
        }
        //Class inArray
        //处理替换array
        if ([c respondsToSelector:@selector(mm_PropertyClassInArray)]) {
            NSDictionary *classInArrays  = [c mm_PropertyClassInArray];
            if (classInArrays) {
                _ClassInArrays = classInArrays;
            }
        }
        self->_isNewValueReplaceOldValue = [c instancesRespondToSelector:@selector(mm_NewValueReplaceOldValueKey:old:)];
        
        //替换的key
        NSDictionary *replaceNameDict = nil;
        NSMutableDictionary *ClassMoresKeys = nil;
        BOOL _isReplaceName = NO , _isReplaceMoreName = NO;
        if([c respondsToSelector:@selector(mm_ReplacePropertyName)]) {  //是否执行了
            replaceNameDict = [c mm_ReplacePropertyName]; //拿到字典
            ClassMoresKeys = [NSMutableDictionary new];
            [replaceNameDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *strObj = (NSString *)obj;
                    NSArray *comp = [strObj componentsSeparatedByString:@"."];
                    if (comp.count > 1) {
                        ClassMoresKeys[key] = comp;
                    }
                }
            }];
            if (replaceNameDict) {
                _isReplaceName = YES;
                self->_MappingPropertyMetas = [NSMutableArray new];
                _isReplaceMoreName = ClassMoresKeys.count;
                if (_isReplaceMoreName) {
                    self->_MappingMorePropertyMetas = [NSMutableArray new];
                }
            }
            
        }
        self->_PropertyNames = [NSMutableArray new];
        self->_PropertyMetas = [NSMutableArray new];
        while (c) {
            if (c == [NSObject class]) break;
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(c, &ivarCount);
            for (int i = 0 ; i < ivarCount; i++) {
                Ivar ivar = ivars[i];
                SQPropertyMetaInfo * meta = [[SQPropertyMetaInfo alloc] initWithMetaInfoIvar:ivar Class:c];
                if (meta == nil) continue;
                NSString *name = meta->_name;
                if (whileList)if (![whileList containsObject:name]) continue;
                if (blackList)if ([blackList  containsObject:name]) continue;
                [self->_PropertyNames addObject:name];
                if (self->_ClassInArrays) {
                    Class mappingClass = self->_ClassInArrays[name];
                    if (mappingClass) {
                        meta->_mappingInArray = mappingClass;
                    }
                }
                if (_isReplaceMoreName){
                    NSArray *moreKeys = ClassMoresKeys[name];
                    if (moreKeys) {
                        meta->_replaceMoreNames = moreKeys;
                        [self->_MappingMorePropertyMetas addObject:meta];
                        continue;
                    }
                }
                if (_isReplaceName){
                    NSString *replaceName =  replaceNameDict[name];
                    if (replaceName ) {
                        meta->_replaceName = replaceName;
                        [self->_MappingPropertyMetas addObject:meta];
                        continue;
                    }
                }
                [self->_PropertyMetas addObject:meta];
            }
            free(ivars);
            c = class_getSuperclass(c);
            
        }
    }
    
    return self;
    
}
+(instancetype)initWithMetaClass:(Class)c{
    static NSMutableDictionary *_ClassMetas;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ClassMetas = [NSMutableDictionary new];
    });
    SQClassMeta *meta = [_ClassMetas objectForKey:NSStringFromClass(c)];
    if (meta) return meta;
    meta = [[SQClassMeta alloc] initWithClass:c];
    if (meta) {
        _ClassMetas[NSStringFromClass(c)] = meta;
    }
    return meta;
}
@end

@implementation NSObject (SQLExtension)
static  id NumberValueFromStringValue(NSString *value){
    static NSDictionary *valueKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        valueKeys = @{
                      @"1"   :@YES,
                      @"YES" :@YES,
                      @"yes" :@YES,
                      @"TRUE":@YES,
                      @"true":@YES,
                      @"FALSE":@NO,
                      @"false":@NO,
                      @"NO" :@NO,
                      @"no" :@NO,
                      @"No" :@NO,
                      @"0"  :@NO,
                      };
    });
    
    if ([valueKeys.allKeys containsObject:value])return valueKeys[value];
    return value;
}

static  NSMutableArray *ArrayJSONObjectToModel(NSArray *array,Class cl){
    NSMutableArray *models = [NSMutableArray new];
    for (id dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) break;
        id model = [cl mm_ModelObjectWithJSON:dict];
        [models addObject:model];
    }
    return models.count ? models : nil;
}
static void ModelValueMappingJSONObject(id self, id value , SQPropertyMetaInfo *meta , BOOL isNewOld){
    @try {
        id key  = meta->_name;
        if (isNewOld) {
            id  newValue = [self mm_NewValueReplaceOldValueKey:key old:value];
            if (newValue==nil) return;
            if (newValue != value) {
                ((void(*)(id ,SEL ,id))(void *)objc_msgSend)(self,meta->_set,newValue);
                return;
            }
        }
        static NSNumberFormatter *numberFormatter =  nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            numberFormatter = [NSNumberFormatter new];
        });
        if (!meta->_isNS) {
            if ([value isKindOfClass:[NSString class]]) {
                switch (meta->_numberType) {
                    case _typeBool:
                    case _typebool:
                    case _typeInt:{
                        value = NumberValueFromStringValue(value);
                    }break;
                    default:
                        value =  [numberFormatter numberFromString:value];
                        break;
                }
            }
            [self setValue:value forKey:key];
            return;
        }else {
            switch (meta->_isNSType) {
                case _typeNSString:
                case _typeNSMutableString:{
                    if ([value isKindOfClass:[NSURL class]]) {
                        NSURL *urlStirngValue = (NSURL *)value;
                        value = urlStirngValue.absoluteString;
                    }else if ([value isKindOfClass:[NSNumber class]]) { //is number
                        NSNumber *numberValue = value;
                        value = numberValue.description;
                    }
                }break;
                case _typeNSURL:{
                    if ([value isKindOfClass:[NSURL class]])break;
                    if ([value isKindOfClass:[NSString class]]) {
                        value = [NSURL URLWithString:value];
                    }
                }break;
                case _typeNSDictionary:
                case _typeNSMutableDictionary:{
                    Class cl = meta->_mappingInArray;
                    if (!cl) break;
                    if ([value isKindOfClass:[NSDictionary class]]){
                        NSMutableDictionary *superDict = [NSMutableDictionary new];
                        [value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                            if ([obj isKindOfClass:[NSDictionary class]]||
                                [obj isKindOfClass:[NSMutableDictionary class]]
                                ) { //字典里面还是字典
                                id valueClass = [cl mm_ModelObjectWithJSON:obj];
                                superDict[key] = valueClass;
                            }
                        }];
                        value = superDict.count ? superDict : value;
                    }
                }break;
                case _typeNSArray:
                case _typeNSMutableArray:{
                    Class cl = meta->_mappingInArray;
                    if (!cl) break;
                    if ([value isKindOfClass:[NSArray class]]) {
                        NSMutableArray *classs = ArrayJSONObjectToModel(value,cl);
                        value = !classs ?value :classs;
                    }
                }break;
                case _typeObject:{
                    if ([value isKindOfClass:[NSDictionary  class]]) {
                        id obj = [meta->_propertyClass new];
                        [obj mm_ModelWithDictJSON:value];
                        value = obj;
                    }
                }break;
                case _typeNSData:
                case _typeNSMutableData:{
                    if ([value isKindOfClass:[NSString class]]) {
                        value = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_isNSType == _typeNSMutableData) {
                            value  = [value mutableCopy];
                        }
                    }
                }break;
                case _typeNSNumber:
                case _typeNSDecimalNumber:{
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_isNSType == _typeNSNumber) {
                            value =  [numberFormatter numberFromString:value];
                        }else if (meta->_isNSType == _typeNSDecimalNumber){
                            value = [NSDecimalNumber decimalNumberWithString:value];
                        }
                    }
                }
                default:
                    break;
            }
            
        }
        if (![value isKindOfClass:meta->_propertyClass]) return;
        ((void(*)(id ,SEL ,id))(void *)objc_msgSend)(self,meta->_set,value);
    } @catch (NSException *exception) {}
    
}
static  void  ModelValueWithJSONObject(id self,id dict){
    @autoreleasepool {
        if (!dict) return;
        SQClassMeta *ClassMeta = [SQClassMeta  initWithMetaClass:object_getClass(self)];
        BOOL isNewValueReplaceOldNew = ClassMeta->_isNewValueReplaceOldValue;
        for (SQPropertyMetaInfo *meta in ClassMeta->_MappingPropertyMetas) {
            id value = dict[meta->_replaceName];
            if (value == nil || value == [NSNull null])continue;
            ModelValueMappingJSONObject(self , value , meta,isNewValueReplaceOldNew);
        }for (SQPropertyMetaInfo *meta in ClassMeta->_PropertyMetas) {
            id value = dict[meta->_name];
            if (value == nil || value == [NSNull null])continue;
            ModelValueMappingJSONObject(self , value , meta,isNewValueReplaceOldNew);
        }for (SQPropertyMetaInfo *meta in ClassMeta->_MappingMorePropertyMetas) {
            id value = nil;
            id newObjectDict = [dict mutableCopy];
            for (NSString *countsKey in meta->_replaceMoreNames) {
                if (![newObjectDict isKindOfClass:[NSDictionary class]]) {
                    value = newObjectDict;
                }else{
                    value = [newObjectDict objectForKey:countsKey];
                    if (value) {
                        newObjectDict = value;
                        value = newObjectDict;
                    }
                }
            }
            if (value == nil || value == [NSNull null])continue;
            ModelValueMappingJSONObject(self ,value ,meta,isNewValueReplaceOldNew);
            
        }
        
    }
}

static  NSMutableArray *ArrayObjectToJSONObject(NSArray *objs){
    NSMutableArray *jsons = [NSMutableArray new];
    for (id model in objs) {
        if (PropertyFoundtaionType(object_getClass(model)) != _typeObject)break;
        id dict = [model mm_JSONWithModel];
        [jsons addObject:dict];
    }
    return jsons.count ? jsons : nil;
}

static id JSONValueToModelProperty(SQPropertyMetaInfo *meta , id value){
    switch (meta->_isNSType) {
        case _typeObject:{
            value= JSONObjectMappingModelObject(value);
        }break;
        case _typeNSDate:{
            value = ((NSDate *)value).description;
        }break;
        case _typeNSURL:{
            value = ((NSURL *)value).absoluteString;
        }break;
        case _typeNSDictionary:
        case _typeNSMutableDictionary:{
            if (!meta->_mappingInArray)break;
            value = [NSMutableDictionary dictionaryWithDictionary:value];
            NSMutableDictionary *superDict = [NSMutableDictionary new];
            [(NSMutableDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if(PropertyFoundtaionType(object_getClass(obj)) == _typeObject){
                    id json =[obj mm_JSONWithModel];
                    if (json)superDict[key] = json;
                }else{
                    *stop = YES;
                }
            }];
            value = superDict.count ? superDict : value;
        }break;
        case _typeNSArray:
        case _typeNSMutableArray:{
            if (!meta->_mappingInArray)break;
            NSMutableArray *models = ArrayObjectToJSONObject(value);
            value = models ? models : value;
        }
        default:
            break;
    }
    return value;
    
}

static id JSONObjectMappingModelObject(id self){
    @try {
        @autoreleasepool {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            SQClassMeta *ClassMeta = [SQClassMeta initWithMetaClass:object_getClass(self)];
            for (SQPropertyMetaInfo *meta in ClassMeta->_MappingPropertyMetas) {
                id value = [self valueForKey:meta->_name];
                if (value == nil || value == [NSNull null])continue;
                id  NewValue = JSONValueToModelProperty(meta , value);
                dict[meta->_replaceName] = NewValue;
            }for (SQPropertyMetaInfo *meta in ClassMeta->_PropertyMetas) {
                id value = [self valueForKey:meta->_name];
                if (value == nil || value == [NSNull null])continue;
                id  NewValue = JSONValueToModelProperty(meta , value);
                dict[meta->_name] = NewValue;
            }for (SQPropertyMetaInfo *meta in ClassMeta->_MappingMorePropertyMetas) {
                id value = [self valueForKey:meta->_name];
                if (value == nil || value == [NSNull null])continue;
                
                id  NewValue = JSONValueToModelProperty(meta , value);
                NSArray * moresComp = meta->_replaceMoreNames;
                if (moresComp) {
                    NSMutableDictionary *values = dict;
                    for (int i = 0, over = (int)moresComp.count; i < over; i++) {
                        NSString *nextKey = nil;
                        if (i != over - 1) {
                            nextKey = moresComp[i + 1];
                        }
                        if (nextKey) {
                            id tempSuperDict = values[moresComp[i]];
                            if (tempSuperDict == nil) {
                                tempSuperDict = [NSMutableDictionary new];
                                values[moresComp[i]] = tempSuperDict;
                            }
                            values = tempSuperDict;
                        }else{
                            @try {
                                if (values[moresComp[i]] == nil) {
                                    values[moresComp[i]] = NewValue;
                                }
                            } @catch (NSException *exception) {}
                        }
                    }
                }
                
            }
            return dict;
        }
        
    } @catch (NSException *exception) {}
}

static void Encode(id self , NSCoder *encode){
    SQClassMeta *ClassMeta = [SQClassMeta initWithMetaClass:object_getClass(self)];
    for (NSString *metaName in ClassMeta->_PropertyNames) {
        id value =  [self valueForKey:metaName];
        if (value!= nil) {
            [encode encodeObject:value forKey:metaName];
        }
    }
}

static void Decode(id self , NSCoder *decode){
    SQClassMeta *ClassMeta = [SQClassMeta initWithMetaClass:object_getClass(self)];
    for (NSString *metaName in ClassMeta->_PropertyNames) {
        id value =  [decode decodeObjectForKey:metaName];
        if (value!= nil) {
            [self setValue:value forKey:metaName];
        }
    }
}
static NSDictionary *JSONObjectTransform(id dict){
    if ([dict isKindOfClass:[NSDictionary class]])return dict;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) return dict;
    if ([dict isKindOfClass:[NSString class]] || [dict isKindOfClass:[NSMutableString class]]) {
        return  [NSJSONSerialization JSONObjectWithData:[((NSString *)dict) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    }else if ([dict isKindOfClass:[NSData class]] || [dict isKindOfClass:[NSMutableData class]]){
        return [NSJSONSerialization JSONObjectWithData:dict options:kNilOptions error:nil];
    }
    return nil;
}


-(void)mm_ModelWithDictJSON:(id)dict{
    ModelValueWithJSONObject(self,JSONObjectTransform(dict));
}
+(instancetype)mm_ModelObjectWithDataJSON:(NSData *)json{
    return [self mm_ModelObjectWithJSON:json];
}
+(instancetype)mm_ModelObjectWithStringJSON:(NSString *)json{
    return [self mm_ModelObjectWithJSON:json];
}
+(instancetype)mm_ModelObjectWithJSON:(id)json{
    id self_ = [[self alloc] init];
    [self_ mm_ModelWithDictJSON:json];
    return self_;
}
-(id)mm_JSONWithModel{
    return JSONObjectMappingModelObject(self);
}
-(NSString *)mm_JSONStringWithModel{
    return [[NSString alloc]initWithData:[self mm_JSONDataWithModel] encoding:NSUTF8StringEncoding];
}
-(NSData *)mm_JSONDataWithModel{
    return [NSJSONSerialization dataWithJSONObject:[self mm_JSONWithModel] options:kNilOptions error:nil];
}
//编码
- (void)mm_ModelEncode:(NSCoder *)encode{
    Encode(self,encode);
}
//解码
- (void)mm_ModelDecode:(NSCoder *)decode{
    Decode(self, decode);
    
}

@end


