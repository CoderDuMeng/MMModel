 //
//  NSObject+SQLExtension.m
//  SQliteExample



#import "NSObject+SQLExtension.h"  
#import "SQLProperty.h" 
static NSMutableDictionary * _classPropertyClassInArrays;
static NSMutableDictionary * _classPropertyKeyMoresCounts;
static NSMutableDictionary * _classPropertyValues;
static CFMutableDictionaryRef _classPropertyReplaceValues;
static CFMutableDictionaryRef _classPropertyBlackListValues;
static CFMutableDictionaryRef _classPropertyWhiteListValues;
static CFMutableDictionaryRef _classPropertyBlackWhiteis;
static sqinline void propertyMeteCache(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _classPropertyClassInArrays = [NSMutableDictionary dictionary];

        //有多级映射的key
        _classPropertyKeyMoresCounts = [NSMutableDictionary dictionary];
        
        //缓存属性模型
        _classPropertyValues = [NSMutableDictionary dictionary];
        
        //缓存替换的属性key
        _classPropertyReplaceValues = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        //黑名单
        _classPropertyBlackListValues = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        //白名单  
        _classPropertyWhiteListValues = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        //是否处理过
        _classPropertyBlackWhiteis = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
    });
}
static sqinline BOOL blackWhiteListProperty(Class cl){
    //处理过就不用处理了
    if (CFDictionaryGetValue(_classPropertyBlackWhiteis, (__bridge const void *)(cl))) {
        return  YES;
    }
    //while  只有这个数组里面的值才能进行转换
    if (!CFDictionaryGetValue(_classPropertyWhiteListValues, (__bridge const void *)(cl))) {
        if ([cl respondsToSelector:@selector(mm_whitePropertyList)]) {
            NSArray *whilelist = [cl mm_whitePropertyList];
            if (whilelist!=nil) {
                CFDictionarySetValue(_classPropertyWhiteListValues, (__bridge const void *)(cl),(__bridge const void *)(whilelist));
            }
        }else{
            return NO;
            
        }
    }
    //black  这个数组里面的的key不用转换
    if (!CFDictionaryGetValue(_classPropertyBlackListValues, (__bridge const void *)(cl))){
        if ([cl respondsToSelector:@selector(mm_blackPropertyList)]) {
            NSArray *blacklist = [cl mm_blackPropertyList];
            if (blacklist!=nil) {
                CFDictionarySetValue(_classPropertyBlackListValues, (__bridge const void *)(cl),(__bridge const void *)(blacklist));
            }
        }else{
            return NO;
        }
    }
    
   CFDictionarySetValue(_classPropertyBlackWhiteis, (__bridge const void *)(cl),(__bridge const void *)(NSStringFromClass(cl)));
   
    return YES;
}

static sqinline BOOL customPropertyFormBlackWithes(Class c ,NSString *key){
    
    key = [key copy]; 
    NSArray *blacklist = CFDictionaryGetValue(_classPropertyBlackListValues, (__bridge const void *)(c));
    if (blacklist) {
        if ([blacklist containsObject:key]) {
            return YES;
        }
    }
    NSArray *whitelist = CFDictionaryGetValue(_classPropertyWhiteListValues, (__bridge const void *)(c));
    if (whitelist) {
        if (![whitelist containsObject:key]) {
            return YES;
         }
    }
    
    return NO;
    
}


static sqinline NSDictionary * respendsToSelectorReplacePropertyName(Class c){
    NSDictionary *replaceNames =  CFDictionaryGetValue(_classPropertyReplaceValues, (__bridge const void *)(c));
    if (replaceNames!=nil) {
        return replaceNames;
    }
    
    if (_classPropertyClassInArrays[NSStringFromClass(c)] == nil) {
        //处理替换array
        if ([c respondsToSelector:@selector(mm_propertyClassInArray)]) {
            NSDictionary *classInArrays  = [c mm_propertyClassInArray];
            if (classInArrays) {
                _classPropertyClassInArrays[NSStringFromClass(c)] = classInArrays;
                
            }
        }
    }
    
    if([c respondsToSelector:@selector(mm_replacePropertyName)]) {  //是否执行了
        NSDictionary *replaceNameDict = [c mm_replacePropertyName]; //拿到字典
        if (replaceNameDict) {
            CFDictionarySetValue(_classPropertyReplaceValues, (__bridge const void *)(c),(__bridge const void *)([replaceNameDict mutableCopy]));
            //处理多级映射
            if (_classPropertyKeyMoresCounts[NSStringFromClass(c)] == nil) {
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
                
                _classPropertyKeyMoresCounts[NSStringFromClass(c)] = moreDicts;
            }
            
            return replaceNameDict;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}
//处理key  and value
static sqinline id  propertyKey(NSString *key , Class cl,id dict){
    id value;
    
    //是不是多级
    NSArray *moresReplaceName = _classPropertyKeyMoresCounts[NSStringFromClass(cl)][key];
    if (moresReplaceName!=nil && moresReplaceName.count) { //有多级映射的key
        id newObjectDict = [dict mutableCopy];
        for (NSString *countsKey in moresReplaceName) {
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
    }else{

    //处理key 先去缓存
    NSMutableDictionary *propertyKeys = CFDictionaryGetValue(_classPropertyReplaceValues, (__bridge const void *)(cl));
    if (propertyKeys.count && propertyKeys!= nil) {
      
        NSString *replaceName   = propertyKeys[key];
        if (replaceName) {
           key = replaceName;
        }
    }else{
        
        //设置缓存替换的key
        NSDictionary *replaceNames = respendsToSelectorReplacePropertyName(cl);
        if (replaceNames!= nil) {
            NSString *replaceName =  replaceNames[key];
            if (replaceName) {
                key = replaceName;
            }
        }
        
  
    }
    //取值
    value = dict[key];
 }
 
  return value;
  
}
@implementation NSObject (SQLExtension)

+(void)load{
    //设置缓存
    propertyMeteCache();
  
}


- (void)enmunerateSuperClass:(void(^)(Class supuerClass))block{
    Class c = self.class;
      while (c != nil) {
          if (c == [NSObject class]) {
              break;
          }
        if (block) {
            block(c);
        }
        c = class_getSuperclass(c);
    }
}
- (void)enumerateProperty:(void(^)(SQLProperty *property))block{
    //检查黑白名单
    Class selfClass = self.class;
    BOOL isWhiteBlack = blackWhiteListProperty(selfClass);
    respendsToSelectorReplacePropertyName(selfClass);
    NSString *c = NSStringFromClass(selfClass);
    NSMutableArray *classPros = _classPropertyValues[c];
    if (classPros&&classPros.count!=0) {
        for (SQLProperty *property in classPros) {
            if (block) {
                block(property);
            }
        }
    }else{
    
     classPros = [NSMutableArray new];
        
    //找父类
    [self enmunerateSuperClass:^(__unsafe_unretained Class supuerClass) {
        if (supuerClass) {
           
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(supuerClass, &ivarCount);
           
            for (int i = 0 ; i < ivarCount; i++) {
                Ivar ivar = ivars[i];
                SQLProperty * property = [[SQLProperty alloc] initWithIvar:ivar class:supuerClass];
                
                if (isWhiteBlack) { // is  H B
                    if (customPropertyFormBlackWithes(selfClass, property.propertyName)) {
                        continue;
                    }
                }
                [classPros addObject:property];
                
             if (block) {
                 block(property);
             }
            
        }
                
         free(ivars);
            
        _classPropertyValues[c] = classPros;
           
    }
}];
     
}

}


static sqinline NSMutableArray *objecValuesFromArray(NSArray *array,Class cl){
    if (array==nil) return nil;
    NSMutableArray *models = [NSMutableArray new];
    for (id dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) break;
        id model = [cl mm_ModelObjectWithDictJson:dict];
        [models addObject:model];
    }
    return models.count ? models : nil;
}

static sqinline void objectValueFromJsonObject(id self,id dict){
    
    [self enumerateProperty:^(SQLProperty *property) {
        
        NSString *key = property.propertyName;
        Class modelClsss = property.modelClass;
        Class classType  = property.ClassType;
        SEL selector = property.setSel;
        
        //取值
        id value = propertyKey(key,[self class],dict);
        
        if (value == nil || value == [NSNull null]) return;
        
        
        if ([value isKindOfClass:[NSArray class]]) { //处理不可变
            NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:value];
            value = mutableArray;
            
        }else if ([value isKindOfClass:[NSDictionary class]]){
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:value];
            value = mutableDict;
            
        }
        
        // is Model
        if (classType) {
            
            //是模型类型
            if (property.isModelClass) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    id obj = [classType new];
                    [obj objcKeyValue:value];
                    ((void(*)(id,SEL,Class))(void *)objc_msgSend)(self,selector,obj);
                }
            }else{
                if (classType==[NSString class]||
                    classType==[NSMutableString class]) {
                    //is NSURL Class
                    if ([value isKindOfClass:[NSURL class]]) {
                        NSURL *urlStirngValue = (NSURL *)value;
                        ((void(*)(id,SEL,NSString *))(void *)objc_msgSend)(self,selector,urlStirngValue.absoluteString);
                    }else if ([value isKindOfClass:[NSNumber class]]) { //is number
                        NSString *stringValueForNumebr = [NSString stringWithFormat:@"%@",value];
                        ((void(*)(id,SEL,NSString *))(void *)objc_msgSend)(self,selector,stringValueForNumebr);
                    }else{
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)(self,selector,value);
                    }
                    
                }else if ([value isKindOfClass:[NSString class]]){
                    value = [NSMutableString stringWithString:value];
                    // is NSURL Class
                    if (classType == [NSURL class]) {
                        NSURL *urlValue = (NSURL *)value;
                        ((void(*)(id,SEL,NSURL *))(void *)objc_msgSend)(self,selector,urlValue);
                        
                    }else if (classType == [NSDate class]){
                        
                        NSDate *date = nil;
                        {
                            NSDateFormatter *formatter = [NSDateFormatter  new];
                            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                            date =  [formatter dateFromString:(NSString *)value];
                            
                        }
                        {
                            NSDateFormatter *formatter = [NSDateFormatter  new];
                            formatter.dateFormat = @"yyyy-MM-dd ";
                            date =  [formatter dateFromString:(NSString *)value];
                            
                        }
                        {
                            NSDateFormatter *formatter = [NSDateFormatter  new];
                            formatter.dateFormat = @"HH:mm:ss";
                            date = [formatter dateFromString:(NSString *)value];
                        }
                        
                        if (date) {
                            ((void(*)(id,SEL,NSDate *))(void *)objc_msgSend)(self,selector,date);
                        }
                    }else if (classType == [NSValue class]){
                        // is NSValue Class
                        NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                        NSDecimal dec = decNum.decimalValue;
                        if (dec._length == 0 && dec._isNegative) {
                            decNum = nil;
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(self, selector, decNum);
                    }
                    
                    
                } else if (classType==[NSDictionary class]||
                           classType==[NSMutableDictionary class]){
                    NSDictionary *classDict = _classPropertyClassInArrays[NSStringFromClass(modelClsss)];
                    if (classDict!= nil && classDict[key]) {
                        Class cl = classDict[key];
                            if ([value isKindOfClass:[NSDictionary class]]||
                                [value isKindOfClass:[NSMutableDictionary class]]
                                ) {
                                NSMutableDictionary *valued = value;
                                __block NSMutableDictionary *superDict = [NSMutableDictionary new];
                                [valued enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                                    if ([obj isKindOfClass:[NSDictionary class]]||
                                        [obj isKindOfClass:[NSMutableDictionary class]]
                                        ) { //字典里面还是字典
                                        id valueClass = [cl mm_ModelObjectWithDictJson:obj];
                                        superDict[key] = valueClass;
                                    }else if ([obj isKindOfClass:[NSArray class]] ||
                                              [obj isKindOfClass:[NSMutableArray class]]
                                              ){
                                        NSMutableArray *models =  objecValuesFromArray(obj,cl);
                                        superDict[key] = !models ? models : @[];
                                    }
                                }];
                              ((void(*)(id,SEL,NSMutableDictionary *))(void *)objc_msgSend)(self,selector,superDict.count==0 ? value : superDict);
                            }
                    }else{
                        ((void(*)(id,SEL,NSMutableDictionary *))(void *)objc_msgSend)(self,selector,(NSMutableDictionary *)value);
                  }
               }else if (classType ==[NSArray class]||
                          classType ==[NSMutableArray class]){
                    NSDictionary *classDict = _classPropertyClassInArrays[NSStringFromClass(modelClsss)];
                    if (classDict!= nil && classDict[key]) {
                        Class  cl =  classDict[key];
                         NSMutableArray *classs = objecValuesFromArray(value,cl);
                         ((void(*)(id,SEL,NSMutableArray *))(void *)objc_msgSend)(self,selector,(NSMutableArray *)classs);
                    }else{
                        ((void(*)(id,SEL,NSMutableArray *))(void *)objc_msgSend)(self,selector,(NSMutableArray *)value);
                    }
                }else{
                    // is other
                    ((void(*)(id,SEL,id))(void *)objc_msgSend)(self,selector,value);
                }
                
            }
            
        }else{
            
            switch (property.typeCode) {
                case _typeInt:
                    if ([value isKindOfClass:[NSString class]]) {
                        ((void(*)(id,SEL,int))(void *)objc_msgSend)(self,selector,[value intValue]);
                    }else{
                        ((void(*)(id,SEL,int))(void *)objc_msgSend)(self,selector,[value intValue]);
                    }
                    break;
                    
                case _typeUnsignedInt:
                    if ([value isKindOfClass:[NSString class]]) {
                        ((void(*)(id,SEL, int))(void *)objc_msgSend)(self,selector,[value intValue]);
                    }else{
                        ((void(*)(id,SEL,unsigned int))(void *)objc_msgSend)(self,selector,[value unsignedIntValue]);
                    }
                    break;
                case _typeBool:
                    if ([value isKindOfClass:[NSString class]]) {
                        ((void(*)(id,SEL,BOOL))(void *)objc_msgSend)(self,selector,[value boolValue]);
                    }else{
                        ((void(*)(id,SEL,BOOL))(void *)objc_msgSend)(self,selector,[value boolValue]);
                    }
                    break;
                case _typeDouble:
                    if ([value isKindOfClass:[NSString class]]) {
                    ((void(*)(id,SEL,double))(void *)objc_msgSend)(self,selector,[value doubleValue]);
                    }else{
                    ((void(*)(id,SEL,double))(void *)objc_msgSend)(self,selector,[value doubleValue]);
                    }
                    break;
                case _typeChar:
                case _typebool:
                    if ([value isKindOfClass:[NSString class]]) {
                        
                        if ([value isEqualToString:@"YES"] ||
                            [value isEqualToString:@"yes"]) {
                            
                            ((void(*)(id,SEL,BOOL))(void *)objc_msgSend)(self,selector,1);
                            
                        }else if ([value isEqualToString:@"true"] ||
                                  [value isEqualToString:@"NO"] ||
                                  [value isEqualToString:@"no"]){
                            
                            ((void(*)(id,SEL,BOOL))(void *)objc_msgSend)(self,selector,0);
                            
                        }else{
                            
                            NSString *charStr = (NSString *) value;
                            
                            ((void(*)(id,SEL,char))(void *)objc_msgSend)(self,selector,(char )charStr.UTF8String);
                        }
                        
                    }else{
                        ((void(*)(id,SEL,char))(void *)objc_msgSend)(self,selector,[value charValue]);
                        
                    }
                    break;
                case _typeShort:
                    ((void(*)(id,SEL, short ))(void *)objc_msgSend)(self,selector,[value shortValue]);
                    break;
                case _typeFloat:
                    if ([value isKindOfClass:[NSString class]]) {
                    ((void(*)(id,SEL,float))(void *)objc_msgSend)(self,selector,[value floatValue]);
                    }else{
                     ((void(*)(id,SEL,float))(void *)objc_msgSend)(self,selector,[value floatValue]);
                  }
                    break;
                case _typeLong:
                    ((void(*)(id,SEL,long))(void *)objc_msgSend)(self,selector,[value longValue]);
                    break;
                case _typeLongLong:
                    if ([value isKindOfClass:[NSString class]]) {
                        ((void(*)(id,SEL,long long))(void *)objc_msgSend)(self,selector,[value longLongValue]);
                    }else{
                        ((void(*)(id,SEL,long long))(void *)objc_msgSend)(self,selector,[value longLongValue]);
                    }
                    break;
                case _typeUnsignedLong:
                    if ([value isKindOfClass:[NSString class]]) {
                        NSString *stringValue = (NSString *)value;
                        ((void(*)(id,SEL, unsigned long ))(void *)objc_msgSend)(self,selector,(unsigned long )[stringValue integerValue]);
                    }else{
                      ((void(*)(id,SEL, unsigned long ))(void *)objc_msgSend)(self,selector,[value unsignedLongValue]);
                    }
                    break;
                case _typeUnsignedLongLong:
                    
                    ((void(*)(id,SEL,unsigned long long))(void *)objc_msgSend)(self,selector,[value unsignedLongLongValue]);
                    break;
                    
                    
                default:
                    break;
            }
            
        }
    }];
    
}


-(void)objcKeyValue:(id)dict{

    NSAssert([[dict class] isSubclassOfClass:[NSDictionary class]], @"不是字典");
    
    if ([self isNoClass]) return;
    @try {
      objectValueFromJsonObject(self, dict);
    } @catch (NSException *exception) {
        NSLog(@"MMModel   objcKeyValue  is  error %@",exception);
        
    }
    
    
}


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

    
    NSString *cl = NSStringFromClass(self.class);
    if (_classPropertyValues[cl]) {
        return NO;
    }
    
    BOOL isC = NO;
    for (Class class in classs) {
        if ([self.class isSubclassOfClass:class]) {
            isC = YES;
            break;
        }
    }
    
    return isC;
    
}

static sqinline NSMutableArray *jsonFormArrayObjects(NSArray *objs){
    if (objs== nil) return nil;
    NSMutableArray *jsons = [NSMutableArray new];
    for (id model in objs) {
        if ([model isNoClass]) {
            break;
        }
        NSMutableDictionary *dict = [model mm_jsonWithModelObject];
        [jsons addObject:dict];
    }
    return jsons.count ? jsons : nil;
 }

static sqinline NSMutableDictionary * jsonObjectFormObject(id self){
    __block   NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [self enumerateProperty:^(SQLProperty *property) {
        
        __block NSString *key = property.propertyName;
        Class  modelClass = property.modelClass;
        id value = [self valueForKey:key];
        if (value == nil || value == [NSNull null]) return;
        if ([value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSMutableDictionary class]])
        {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
            __block NSMutableDictionary *superDict = [NSMutableDictionary new];
            [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]]||
                    [obj isKindOfClass:[NSMutableDictionary class]]) {
                    *stop = YES;
                    return;
                }
                if([obj isKindOfClass:[NSArray class]]||
                   [obj isKindOfClass:[NSMutableArray class]]
                   ){
                    NSMutableArray *models =jsonFormArrayObjects(obj);
                    if (models) {
                        superDict[key] = models;
                    }
                }else{
                    //is model
                    if ([obj isNoClass]) return;
                    id json = [obj valueKey];
                    if (json) {
                      superDict[key] = json;
                    }
                }
            }];
            if (superDict.count!=0) {
                value = superDict;
            }
        }else if ([value isKindOfClass:[NSArray class]]||
                  [value isKindOfClass:[NSMutableArray class]]
                  )
           {
           value = [NSMutableArray arrayWithArray:value];
           NSMutableArray *models = jsonFormArrayObjects(value);
            if (models) {
                value = models;
            }
        }else{ //模型类型
            if (property.isModelClass) {
                value = [value valueKey];
            }
        }
        BOOL ismore = NO;
        NSDictionary *replaceNames = respendsToSelectorReplacePropertyName(modelClass);
        if (replaceNames!=nil) {
            NSString *replaceName = replaceNames[key];
            if (replaceName) {
                NSString *moreKey = [key copy];
                key = replaceName;
                NSDictionary *moresKeys = _classPropertyKeyMoresCounts[NSStringFromClass(modelClass)];
                if (moresKeys!=nil) {
                    NSArray *moresComp = moresKeys[moreKey];
                    if (moresComp) {
                        ismore = YES;
                        NSMutableDictionary *values = dict;
                        for (int i = 0, over = (int)moresComp.count; i < over; i++) {
                            NSString *moreKey = nil;
                            if (i != over - 1) {
                                moreKey = moresComp[i + 1];
                            }
                            if (moreKey) {
                                id tempSuperDict = values[moresComp[i]];
                                if (tempSuperDict == nil) {
                                    tempSuperDict = [NSMutableDictionary new];
                                    values[moresComp[i]] = tempSuperDict;
                                }
                                
                                values = tempSuperDict;
                                
                             }else{
                                 @try {
                                     if (value==nil) return;
                                     if (values[moresComp[i]] == nil) {
                                         values[moresComp[i]] = value;
                                     }
                                 } @catch (NSException *exception) {
                                     NSLog(@"MMModel is error %@",exception);
                                 }
                                 
                            }
                        }
                       
                    }
                }
            }
        }
        
        if (ismore)return;
        
       //赋值
        if (value!=nil && value != [NSNull null] ) {
            
            dict[key] = value;
        }
    }];
    
    return dict;

}

- (NSMutableDictionary *)valueKey{

    if ([self isNoClass]) return nil;
    @try {
      return jsonObjectFormObject(self);
    } @catch (NSException *exception) {
        
        NSLog(@"MMModel is error %@",exception);
        
    }
    
}


//编码
- (void)mm_ModelEncode:(NSCoder *)encode{
    
  [self enumerateProperty:^(SQLProperty *property) {
      NSString *key = property.propertyName;
     
      id value =  [self valueForKey:key];
      
      if (value!= nil) {
    
          [encode encodeObject:value forKey:key];
          
      }
      
  }];
   
}
//解码

- (void)mm_ModelDecode:(NSCoder *)decode{
    
    [self enumerateProperty:^(SQLProperty *property) {
        
        NSString *key = property.propertyName;
        
        id value =  [decode decodeObjectForKey:key];
        
        if (value!= nil) {
            
            [self setValue:value forKey:key];
        }
    
    }];
}

-(void)mm_ModelWithDictJson:(id)dict{
     if ([dict class]==[NSString class]) {
        dict = [NSJSONSerialization JSONObjectWithData:[((NSString *)dict) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    }
    [self objcKeyValue:dict];
}


+(instancetype)mm_ModelObjectWithDictJson:(id)dict{
    
    id self_ = [[self alloc] init];
    [self_ mm_ModelWithDictJson:dict];
    
    return self_;
    
}


-(NSMutableDictionary *)mm_jsonWithModelObject{
    return [self valueKey];
}


@end

@implementation NSObject (SQLFoundation)
+(NSArray *)mm_whitePropertyList{
    return nil;
}
+(NSArray *)mm_blackPropertyList{
    return nil;
}
+(NSDictionary *)mm_replacePropertyName{
    return nil;
}
+(NSDictionary *)mm_propertyClassInArray{
    return nil;
}

@end

