//
//  SQProperty.h

#import <Foundation/Foundation.h>


#define sqinline __inline__  __attribute__((always_inline))

typedef enum {
    _typeNone ,  //<< 没有
    _typeBool ,  //<< BOOL
    _typebool ,  //<< bool
    _typeInt  ,  //<< int
    _typeUnsignedInt, //<< unsiged int
    _typeFloat , //<< float
    _typeDouble , //<< double
    _typeLongLong , //<< long long
    _typeUnsignedLong , //<< unsigedLong
    _typeUnsignedLongLong , //<<  UnsignedLongLong
    _typeLong ,  //<< long
    _typeChar , // char
    _typeShort // short
}type_;

typedef enum {
    _typeFoundationNone,
    _typeObject,
    _typeNSString,
    _typeNSMutableString,
    _typeNSArray,
    _typeNSMutableArray,
    _typeNSSet,
    _typeNSMutableSet,
    _typeNSData,
    _typeNSMutableData,
    _typeNSDictionary,
    _typeNSMutableDictionary,
    _typeNSURL,
     _typeNSDate,
    _typeNSNumber,
    _typeNSDecimalNumber,
    _typeNSValue,
   
    
}typeFoundation_;


type_ PropertyNumberType(const char *type);
typeFoundation_ PropertyFoundtaionType(Class c);








