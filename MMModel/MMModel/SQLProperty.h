//
//  SQProperty.h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>  

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



@interface SQLProperty : NSObject
-(instancetype)initWithIvar:(Ivar )ivar class:(Class )c;
@property (assign , nonatomic , readonly) Class modelClass; //self model class
@property (copy   , nonatomic , readonly) NSString *propertyName;  //property name
@property (assign , nonatomic ,readonly) Class ClassType; //model Class
@property (copy ,nonatomic, readonly) NSString *type; // model type
@property (assign , nonatomic ,readonly) BOOL isModelClass;  //is model
@property (assign , nonatomic,readonly) type_ typeCode;  //type int
@property (assign , nonatomic) BOOL isMoresKeys;  //是否有多级映射
@property (assign , nonatomic) BOOL isReplaceKeys; //是否有替换的key
@property (strong , nonatomic) NSString *PropertyReplaceName;  //替换key
@property (strong , nonatomic) NSArray *PropertyMoresKeys;    //多级映射
@end
