
#import "SQLPropertyType.h"
#import "NSObject+SQLExtension.h"
type_ PropertyNumberType(const char *type){
    type_ t = _typeNone;
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


typeFoundation_ PropertyFoundtaionType(Class c){
    if([c isSubclassOfClass:[NSString class]])            return _typeNSString;
    if([c isSubclassOfClass:[NSMutableString class]])     return _typeNSMutableString;
    if([c isSubclassOfClass:[NSURL class]])               return _typeNSURL;
    if([c isSubclassOfClass:[NSArray class]])             return _typeNSArray;
    if([c isSubclassOfClass:[NSMutableArray class]])      return _typeNSMutableArray;
    if([c isSubclassOfClass:[NSDictionary class]])        return _typeNSDictionary;
    if([c isSubclassOfClass:[NSMutableDictionary class]]) return _typeNSMutableDictionary;
    if([c isSubclassOfClass:[NSSet class]])               return _typeNSSet;
    if([c isSubclassOfClass:[NSMutableSet class]])        return _typeNSMutableSet;
    if([c isSubclassOfClass:[NSData class]])              return _typeNSData;
    if([c isSubclassOfClass:[NSMutableData class]])       return _typeNSMutableData;
    if([c isSubclassOfClass:[NSDecimalNumber class]])     return _typeNSDecimalNumber;
    if([c isSubclassOfClass:[NSNumber class]])            return _typeNSNumber;
    if([c isSubclassOfClass:[NSValue class]])             return _typeNSValue;
    if([c isSubclassOfClass:[NSDate class]])              return _typeNSDate;
    return _typeObject;
}


