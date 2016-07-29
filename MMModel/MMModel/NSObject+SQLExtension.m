 //
//  NSObject+SQLExtension.m
//  SQliteExample



#import "NSObject+SQLExtension.h"  
#import "SQLProperty.h" 

//处理 value
static  id  propertyKey(SQLProperty *property ,id dict){
    id value = nil;
    NSString *key = property.propertyName;
    if (property.isMoresKeys) {
        id newObjectDict = [dict mutableCopy];
        for (NSString *countsKey in property.PropertyMoresKeys) {
            if (![newObjectDict isKindOfClass:[NSDictionary class]]) {
                value = newObjectDict;
            }else{
                value = newObjectDict[countsKey];
                if (value) {
                    newObjectDict = value;
                    value = newObjectDict;
                }
            }
        }
        
        return value;
    }else if (property.isReplaceKeys){
        key = property.PropertyReplaceName;
    }
    //取值
    value = dict[key];

  return value;
  
}

@interface SQClass : NSObject
-(instancetype)initWithClass:(Class )c;
@property (strong , nonatomic) NSDictionary *ClassInArrays;
@property (strong , nonatomic) NSMutableDictionary *ClassMoresKeys;
@property (strong , nonatomic) NSDictionary *ClassReplacePropertyNames;
@property (strong , nonatomic) NSMutableArray <SQLProperty *>*propertys;
@property (assign , nonatomic) BOOL isClassInArrays;

@end
@implementation SQClass
-(instancetype)initWithClass:(Class)c{
    if (self=[super init]) {
        //黑名单
        NSArray *blackList = nil;
        if ([c respondsToSelector:@selector(mm_blackPropertyList)]) {
            blackList = [c mm_blackPropertyList];
        }
        //白名单
        NSArray *whileList = nil;
        if ([c respondsToSelector:@selector(mm_whitePropertyList)]) {
            whileList = [c mm_whitePropertyList];
         }
        //Class inArray
        //处理替换array
        if ([c respondsToSelector:@selector(mm_propertyClassInArray)]) {
            NSDictionary *classInArrays  = [c mm_propertyClassInArray];
            self.ClassInArrays = classInArrays;
            self.isClassInArrays = YES;
        }
        //替换的key
        if([c respondsToSelector:@selector(mm_replacePropertyName)]) {  //是否执行了
            NSDictionary *replaceNameDict = [c mm_replacePropertyName]; //拿到字典
            __block  NSMutableDictionary *moreDicts = [NSMutableDictionary new];
            [replaceNameDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *strObj = (NSString *)obj;
                    NSArray *comp = [strObj componentsSeparatedByString:@"."];
                    if (comp.count > 1) {
                        moreDicts[key] = comp;
                    }
                }
            }];
            self.ClassReplacePropertyNames = replaceNameDict;
            self.ClassMoresKeys = moreDicts;
        }
        
        self.propertys = [NSMutableArray new];
     
        void (^block)(Class c) = ^(Class c){
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(c, &ivarCount);
            for (int i = 0 ; i < ivarCount; i++) {
                Ivar ivar = ivars[i];
                SQLProperty * property = [[SQLProperty alloc] initWithIvar:ivar class:c];
                
                if (whileList)if (![whileList containsObject:property.propertyName]) continue;
                if (blackList)if ([blackList  containsObject:property.propertyName]) continue;
                if (self.ClassReplacePropertyNames){
                    NSString *replaceName =  self.ClassReplacePropertyNames[property.propertyName];
                    if (replaceName) {
                        property.isReplaceKeys = YES;
                        property.PropertyReplaceName = replaceName;
                    }
                    
                }
                if (self.ClassMoresKeys){
                    NSArray *moreKeys = self.ClassMoresKeys[property.propertyName];
                    if (moreKeys) {
                        property.isMoresKeys = YES;
                        property.PropertyMoresKeys = moreKeys;
                    }
                }
                
                [self.propertys addObject:property];
            }
            
            free(ivars);
        };
        
        while (c != nil) {
            if (c == [NSObject class]) break;
            if (block) {
                block(c);
            }
            c = class_getSuperclass(c);
        }
        
        if(!self.ClassMoresKeys) self.ClassMoresKeys = @{}.mutableCopy;
        if(!self.ClassReplacePropertyNames) self.ClassReplacePropertyNames = @{};
        if(!self.ClassInArrays) self.ClassInArrays = @{};
        
    }
  return self;
    
}

@end
@implementation NSObject (SQLExtension)
- (BOOL)isNoClass{
    static  NSArray *classs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classs  =@[[NSString class],
                   [NSMutableString class],
                   [NSMutableArray class],
                   [NSArray class],
                   [NSMutableDictionary class],
                   [NSDictionary class],
                   [NSMutableSet class],
                   [NSSet class],
                   [NSNumber class],
                   [NSURL class],
                   [NSData class],
                   [NSMutableData class],
                   [NSDate class]
                   ];
    });
    BOOL isC = NO;
    for (Class class in classs) {
        if ([self.class isSubclassOfClass:class]){
            isC = YES;
            break;
      }
    }
    return isC;
    
}
static  id numberValueFromStringValue(NSString *value){
    
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

static NSMutableDictionary *_ClassPropertykeys = nil;
- (SQClass *)propertyClassInfo{
    Class c = self.class;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ClassPropertykeys = [NSMutableDictionary new];
    });
    SQClass *ClassInfo = _ClassPropertykeys[NSStringFromClass(c)];
    if (ClassInfo == nil) {
        ClassInfo = [[SQClass alloc] initWithClass:c];
      _ClassPropertykeys[NSStringFromClass(c)] = ClassInfo;
    }
    return  ClassInfo;
}
static  NSMutableArray *objecValuesFromArray(NSArray *array,Class cl){
    if (array==nil) return nil;
    NSMutableArray *models = [NSMutableArray new];
    for (id dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) break;
        id model = [cl mm_ModelObjectWithDictJson:dict];
        [models addObject:model];
    }
    return models.count ? models : nil;
}

static  void objectValueFromJsonObject(id self,id dict){
     SQClass *ClassInfo = [self propertyClassInfo];
    for (SQLProperty *property in ClassInfo.propertys) {
        NSString *key = property.propertyName;
        Class classType  = property.ClassType;
        //取值
        id value = propertyKey(property,dict);
        if (value == nil || value == [NSNull null]){
          continue;
        }
        if ([self respondsToSelector:@selector(mm_newValueReplaceOldValueKey:old:)]) {
           id  newValue = [self mm_newValueReplaceOldValueKey:property.propertyName old:value];
            if (newValue != value) {
                [self setValue:newValue forKey:key];
                continue;
            }
        }
        // is Model
        if (classType) {
            //是模型类型
            if (property.isModelClass) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    id obj = [classType new];
                    [obj objcKeyValue:value];
                    value = obj;
                }
            }else{
                if (classType==[NSString class]||
                    classType==[NSMutableString class]) {
                    //is NSURL Class
                    if ([value isKindOfClass:[NSURL class]]) {
                        NSURL *urlStirngValue = (NSURL *)value;
                        value = urlStirngValue.absoluteString;
                    }else if ([value isKindOfClass:[NSNumber class]]) { //is number
                        NSNumber *numberValue = value;
                        value = numberValue.description;
                    }
                }else if (classType == [NSURL class]){
                    if ([value isKindOfClass:[NSString class]]) {
                        value = [NSURL URLWithString:value];
                    }
                } else if (ClassInfo.isClassInArrays){
                    if(classType==[NSDictionary class]||
                     classType==[NSMutableDictionary class]){
                        Class cl =  ClassInfo.ClassInArrays[property.propertyName];
                        if(cl){
                            if ([value isKindOfClass:[NSDictionary class]]){
                                NSMutableDictionary *superDict = [NSMutableDictionary new];
                                [value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                                    if ([obj isKindOfClass:[NSDictionary class]]||
                                        [obj isKindOfClass:[NSMutableDictionary class]]
                                        ) { //字典里面还是字典
                                        id valueClass = [cl mm_ModelObjectWithDictJson:obj];
                                        superDict[key] = valueClass;
                                    }
                                }];
                                value = superDict;
                            }
                        }
                    }else if (classType ==[NSArray class]||
                              classType==[NSMutableArray class]){
                        Class  cl =  ClassInfo.ClassInArrays[key];
                        if (cl) {
                            NSMutableArray *classs = objecValuesFromArray(value,cl);
                            value = !classs ?value :classs;
                        }
                    }
                }
           }
        }else{
            if ([value isKindOfClass:[NSString class]]) {
                if (property.typeCode&_typeBool ||
                    property.typeCode&_typebool ||
                    property.typeCode&_typeInt) {
                    value = numberValueFromStringValue(value);
                }else{
                    static NSNumberFormatter *numberFormatter =  nil;
                    numberFormatter = [NSNumberFormatter new];
                    value =  [numberFormatter numberFromString:value];
                }
            }
        }
        if (classType && ![value isKindOfClass:classType]) value = nil;
           [self setValue:value forKey:key];
      }
  
}

-(void)objcKeyValue:(id)dict{
    NSAssert([[dict class] isSubclassOfClass:[NSDictionary class]], @"不是字典");
    if ([self isNoClass]) return;
    @try {
        objectValueFromJsonObject(self,dict);
    } @catch (NSException *exception) {
        NSLog(@"MMModel   objcKeyValue  is  error %@",exception);
    }
    
}
static  NSMutableArray *jsonFormArrayObjects(NSArray *objs){
    NSMutableArray *jsons = [NSMutableArray new];
    for (id model in objs) {
        if ([model isNoClass]){
            break;
        }
        NSMutableDictionary *dict = [model mm_jsonWithModelObject];
        [jsons addObject:dict];
    }
    return jsons.count ? jsons : nil;
 }
static NSMutableDictionary * jsonObjectFormModelObject(id self){
    NSMutableDictionary *dict = [NSMutableDictionary new];
    SQClass *classInfo = [self propertyClassInfo];
    for (SQLProperty *property in classInfo.propertys) {
      __block  NSString *key = property.propertyName;
        id value = [self valueForKey:key];
        if (value == nil || value == [NSNull null]){
           continue;
        }
        
        if ([value isKindOfClass:[NSDate class]]) {
            value = ((NSDate *)value).description;
        }else if ([value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSMutableDictionary class]])
        {
             value = [NSMutableDictionary dictionaryWithDictionary:value];
             NSMutableDictionary *superDict = [NSMutableDictionary new];
            [(NSMutableDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if(![obj isNoClass]){
                    id json =[obj mm_jsonWithModelObject];
                    if (json)superDict[key] = json;
                }else{
                    *stop = YES;
                }
            }];
            if (superDict.count) {
                value  = superDict;
            }
        }else if ([value isKindOfClass:[NSArray class]]||
                  [value isKindOfClass:[NSMutableArray class]]
                  ){
                NSMutableArray *models = jsonFormArrayObjects(value);
                if (models){
                    value = models;
                }
        }else{ //模型类型
            if (property.isModelClass){
                value=[value mm_jsonWithModelObject];
            }
        }
        NSArray *moresComp = nil;
        if (property.isMoresKeys) {
            moresComp = property.PropertyMoresKeys;
        }else if (property.isReplaceKeys){
            key = property.PropertyReplaceName;
        }
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
                            values[moresComp[i]] = value;
                        }
                    } @catch (NSException *exception) {
                        NSLog(@"MMModel is error %@",exception);
                    }
                }
            }
        }else{
            dict[key] = value;
        }
    }
    return dict;
}

static NSDictionary *jsonFormidValue(id dict){
    if ([dict isKindOfClass:[NSDictionary class]])return dict;
    if ([dict isKindOfClass:[NSString class]]) {
     return  [NSJSONSerialization JSONObjectWithData:[((NSString *)dict) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    }else if ([dict isKindOfClass:[NSData class]]){
        return [NSJSONSerialization JSONObjectWithData:dict options:kNilOptions error:nil];
    }
    return dict;
}

-(void)mm_ModelWithDictJson:(id)dict{
    NSDictionary *json = jsonFormidValue(dict);
    [self objcKeyValue:json];
}

+(instancetype)mm_ModelObjectWithValueData:(NSData *)json{
    return [self mm_ModelObjectWithDictJson:json];
}
+(instancetype)mm_ModelObjectWithValueString:(NSString *)json{
    return [self mm_ModelObjectWithDictJson:json];
}
+(instancetype)mm_ModelObjectWithDictJson:(id)dict{
    id self_ = [[self alloc] init];
    [self_ mm_ModelWithDictJson:dict];
    return self_;
}
-(NSMutableDictionary *)mm_jsonWithModelObject{
    if ([self isNoClass]) return nil;
    @try {
        return jsonObjectFormModelObject(self);
    } @catch (NSException *exception) {
        NSLog(@"MMModel is error %@",exception);
    }
}

//编码
- (void)mm_ModelEncode:(NSCoder *)encode{
    for (SQLProperty *property in [self propertyClassInfo].propertys) {
        NSString *key = property.propertyName;
        id value =  [self valueForKey:key];
        if (value!= nil) {
            [encode encodeObject:value forKey:key];
        }
    }
}
//解码
- (void)mm_ModelDecode:(NSCoder *)decode{
    for (SQLProperty *property in [self propertyClassInfo].propertys) {
        NSString *key = property.propertyName;
        id value =  [decode decodeObjectForKey:key];
        if (value!= nil) {
          [self setValue:value forKey:key];
        }
    }
}

@end


