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
@property (copy , nonatomic , readonly) NSMutableString *propertyName;  //property name
@property (assign , nonatomic ,readonly) Class ClassType; //model Class
@property (copy ,nonatomic, readonly) NSString *type; // model type
@property (assign , nonatomic ,readonly) SEL getSel; // SEL get
@property (assign , nonatomic ,readonly) SEL setSel; // SEL set
@property (assign , nonatomic ,readonly) BOOL isModelClass;  //is model
@property (assign , nonatomic,readonly) type_ typeCode;  //type int



@end
