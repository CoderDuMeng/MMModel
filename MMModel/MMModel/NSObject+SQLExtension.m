 //
//  NSObject+SQLExtension.m
//  SQliteExample



#import "NSObject+SQLExtension.h"  
#import "SQLProperty.h" 

@interface SQClass : NSObject
-(instancetype)initWithClass:(Class )c;
@property (strong , nonatomic , readonly) NSDictionary *ClassInArrays;
@property (strong , nonatomic , readonly) NSMutableArray <SQLProperty *>*Propertys;
@property (assign , nonatomic , readonly) BOOL isClassInArrays;
@end
@implementation SQClass
-(instancetype)initWithClass:(Class)c{
    if (self=[super init]) {
        if ([c  isNoClass]) return self;
        //黑名单
        NSArray *blackList = nil;
        if ([c respondsToSelector:@selector(mm_BlackPropertyList)]) {
            blackList = [c mm_BlackPropertyList];
        }
        //白名单
        NSArray *whileList = nil;
        if ([c respondsToSelector:@selector(mm_WhitePropertyList)]) {
            whileList = [c mm_WhitePropertyList];
         }
        //Class inArray
        //处理替换array
        if ([c respondsToSelector:@selector(mm_PropertyClassInArray)]) {
            NSDictionary *classInArrays  = [c mm_PropertyClassInArray];
            _ClassInArrays = classInArrays;
            _isClassInArrays = YES;
        }
        //替换的key
        NSDictionary *replaceNameDict = nil;
        NSMutableDictionary *ClassMoresKeys = nil;
        BOOL _isReplaceName , _isReplaceMoreName;
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
            
            _isReplaceName = YES;
            _isReplaceMoreName = ClassMoresKeys.count;
        }
        
        _Propertys = [NSMutableArray new];
        void (^block)(Class c) = ^(Class c){
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(c, &ivarCount);
            for (int i = 0 ; i < ivarCount; i++) {
                Ivar ivar = ivars[i];
                SQLProperty * property = [[SQLProperty alloc] initWithIvar:ivar class:c];
                
                if (whileList)if (![whileList containsObject:property.PropertyName]) continue;
                if (blackList)if ([blackList  containsObject:property.PropertyName]) continue;
                if (_isReplaceName){
                    NSString *replaceName =  replaceNameDict[property.PropertyName];
                    if (replaceName) {
                        property.isReplaceKeys = YES;
                        property.PropertyReplaceName = replaceName;
                    }
                    
                }
                if (_isReplaceMoreName){
                    NSArray *moreKeys = ClassMoresKeys[property.PropertyName];
                    if (moreKeys) {
                        property.isMoresKeys = YES;
                        property.PropertyMoresKeys = moreKeys;
                    }
                }
                
                [self.Propertys addObject:property];
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
        
        if(!self.ClassInArrays) _ClassInArrays = @{};
        
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

static NSMutableDictionary *_ClassPropertykeys = nil;
- (SQClass *)PropertyClassInfo{
    Class c = self.class;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ClassPropertykeys = [NSMutableDictionary new];
    });
    SQClass *ClassInfo = _ClassPropertykeys[NSStringFromClass(c)];
    if (ClassInfo == nil) {
        ClassInfo = [[SQClass alloc] initWithClass:c];
        if (ClassInfo.Propertys.count) {
            _ClassPropertykeys[NSStringFromClass(c)] = ClassInfo;
        }
    }
    return  ClassInfo;
}
static  NSMutableArray *ObjecValuesFromArray(NSArray *array,Class cl){
    if (array==nil) return nil;
    NSMutableArray *models = [NSMutableArray new];
    for (id dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) break;
        id model = [cl mm_ModelObjectWithDictJson:dict];
        [models addObject:model];
    }
    return models.count ? models : nil;
}

static  id  ValueFromPropertyNameAndDict(SQLProperty *property ,id dict){
    id value = nil;
    id key = property.PropertyName;
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

static  void ObjectValueFromJsonObject(id self,id dict){
     SQClass *ClassInfo = [self PropertyClassInfo];
    BOOL isNewValueReplaceOldNew = [self respondsToSelector:@selector(mm_NewValueReplaceOldValueKey:old:)];
    @try {
    for (SQLProperty *property in ClassInfo.Propertys) {
        id key = property.PropertyName;
        Class classType  = property.ClassType;
        //取值
        id value = ValueFromPropertyNameAndDict(property,dict);
        
        if (value == nil || value == [NSNull null]){
          continue;
        }
        if (isNewValueReplaceOldNew) {
          id  newValue = [self mm_NewValueReplaceOldValueKey:key old:value];
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
                    [obj mm_ModelWithDictJson:value];
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
                        Class cl =  ClassInfo.ClassInArrays[property.PropertyName];
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
                                value = superDict.count ? superDict : value;
                            }
                        }
                        
                    }else if (classType ==[NSArray class]||
                              classType ==[NSMutableArray class]){
                         Class cl =  ClassInfo.ClassInArrays[key];
                        if (cl) {
                            NSMutableArray *classs = ObjecValuesFromArray(value,cl);
                            value = !classs ?value :classs;
                        }
                    }
                }
           }
        }else{
            if ([value isKindOfClass:[NSString class]]) {
                if (property.TypeCode&_typeBool ||
                    property.TypeCode&_typebool ||
                    property.TypeCode&_typeInt) {
                    value = NumberValueFromStringValue(value);
                }else{
                    static NSNumberFormatter *numberFormatter =  nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                       numberFormatter = [NSNumberFormatter new];
                    });
                    value =  [numberFormatter numberFromString:value];
                }
            }
        }
        if (classType && ![value isKindOfClass:classType]) continue;
            [self setValue:value forKey:key];
      }
        
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
}

static  NSMutableArray *JsonFormArrayObjects(NSArray *objs){
    NSMutableArray *jsons = [NSMutableArray new];
    for (id model in objs) {
        if ([model isNoClass]){
            break;
        }
        NSMutableDictionary *dict = [model mm_JsonWithModelObject];
        [jsons addObject:dict];
    }
    return jsons.count ? jsons : nil;
 }
static NSMutableDictionary * JsonObjectFormModelObject(id self){
    NSMutableDictionary *dict = [NSMutableDictionary new];
    SQClass *classInfo = [self PropertyClassInfo];
    @try {
    for (SQLProperty *property in classInfo.Propertys) {
      __block  NSString *key = property.PropertyName;
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
                    id json =[obj mm_JsonWithModelObject];
                    if (json)superDict[key] = json;
                }else{
                    *stop = YES;
                }
            }];
            value = superDict.count ? superDict : value;
        }else if ([value isKindOfClass:[NSArray class]]||
                  [value isKindOfClass:[NSMutableArray class]]
                  ){
                NSMutableArray *models = JsonFormArrayObjects(value);
                value = models ? models : value;
        }else{ //模型类型
            if (property.isModelClass){
                value=[value mm_JsonWithModelObject];
            }
        }
        
        if (property.isMoresKeys) {
            NSArray * moresComp = property.PropertyMoresKeys;
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
                            NSLog(@"%@",exception);
                        }
                    }
                }
                continue;
            }
            
        }else if (property.isReplaceKeys){
            key = property.PropertyReplaceName;
        }
    
        dict[key] = value;

    }
    return dict;
        
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
}

static NSDictionary *JsonFormIdValue(id dict){
    if ([dict isKindOfClass:[NSDictionary class]])return dict;
    if ([dict isKindOfClass:[NSMutableDictionary class]]) return dict;
    if ([dict isKindOfClass:[NSString class]] || [dict isKindOfClass:[NSMutableString class]]) {
     return  [NSJSONSerialization JSONObjectWithData:[((NSString *)dict) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    }else if ([dict isKindOfClass:[NSData class]] || [dict isKindOfClass:[NSMutableData class]]){
        return [NSJSONSerialization JSONObjectWithData:dict options:kNilOptions error:nil];
    }
    return [NSDictionary new];
}

-(void)mm_ModelWithDictJson:(id)dict{
     NSDictionary *json = JsonFormIdValue(dict);
     ObjectValueFromJsonObject(self,json);
   
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
-(NSMutableDictionary *)mm_JsonWithModelObject{
    return JsonObjectFormModelObject(self);
}

static void Encode(id self , NSCoder *encode){
    for (SQLProperty *property in [self PropertyClassInfo].Propertys) {
        NSString *key = property.PropertyName;
        id value =  [self valueForKey:key];
        if (value!= nil) {
            [encode encodeObject:value forKey:key];
        }
    }
}

static void Decode(id self , NSCoder *decode){
    for (SQLProperty *property in [self PropertyClassInfo].Propertys) {
        NSString *key = property.PropertyName;
        id value =  [decode decodeObjectForKey:key];
        if (value!= nil) {
            [self setValue:value forKey:key];
        }
    }
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


