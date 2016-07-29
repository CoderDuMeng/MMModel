
#import "SQLProperty.h"
#import "NSObject+SQLExtension.h" 
static inline type_ typeCode(const char *type){
    type_ t;
    switch (*type) {
        case 'i':
            t = _typeInt;
            break;
        case 'I':
            t  = _typeUnsignedInt;
            break;
        case 'b':
            t = _typeBool;
            break;
        case 'B':
            t = _typebool;
            break;
        case 's':
            t = _typeShort;
            break;
        case 'c':
            t = _typeChar;
            break;
        case 'l':
            t = _typeLong;
            break;
        case 'f':
            t = _typeFloat;
            break;
        case 'd':
            t = _typeDouble;
            break;
        case 'q':
            t = _typeLongLong;
            break;
        case 'L':
            t = _typeUnsignedLong;
            break;
        case 'Q':
            t = _typeUnsignedLongLong;
            break;
        default:
            break;
    }
    
    return t;
    
}

@implementation SQLProperty


-(instancetype)initWithIvar:(Ivar)ivar class:(__unsafe_unretained Class)c{
    if (self= [super init]) {
        _modelClass = c;
        const char  *charType =  ivar_getTypeEncoding(ivar);
        //属性类型
        NSMutableString *type  = [NSMutableString  stringWithUTF8String:charType];
        _type = [type mutableCopy];
        //对象类型
        if ([type hasPrefix:@"@"]) {
            _type =  [type substringWithRange:NSMakeRange(2, type.length-3)];
            _ClassType = NSClassFromString(_type);
           _isModelClass = ![_ClassType isNoClass];
         
        }else{
            _typeCode = typeCode(charType);
        }
        //属性名字
        NSMutableString *key  = [NSMutableString stringWithUTF8String:ivar_getName(ivar)];
        [key replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        _propertyName = [key copy];
 
        
        
    }
    return self;
}

@end
