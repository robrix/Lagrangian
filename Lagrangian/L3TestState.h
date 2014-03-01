#ifndef L3_TEST_STATE_H
#define L3_TEST_STATE_H

#import <Foundation/Foundation.h>
#import <Lagrangian/L3Defines.h>


#pragma mark API

#if defined(L3_INCLUDE_TESTS)

#define l3_setup(name, ...) \
	_l3_setup(name, __VA_ARGS__)

#define _l3_setup(name, declarations, ...) \
	@protocol _l3_state_protocol_name(name) <NSObject> \
	_l3_declarations_as_properties declarations \
	@end \
	\
	@interface L3Test (_l3_state_protocol_name(name)) \
	@property (readonly) L3TestState<_l3_state_protocol_name(name)> *state; \
	@end \
	\
	L3_CONSTRUCTOR void metamacro_concat(L3TestStateConstructor, name)(void) { \
		L3Test *suite = [L3Test suiteForFile:@(__FILE__) inImageForAddress:metamacro_concat(L3TestStateConstructor, name)]; \
		suite.statePrototype = (id)L3TestStatePrototypeDefine(@protocol(_l3_state_protocol_name(name)), ^(L3Test *self){ (__VA_ARGS__)(); }); \
	}

#define _l3_declaration_as_property(_, each) \
	@property each; \

#define _l3_declarations_as_properties(...) \
	metamacro_foreach(_l3_declaration_as_property, , __VA_ARGS__)

#define _l3_state_protocol_name(name) \
	metamacro_concat(metamacro_concat(L3, name), State)

#else // defined(L3_INCLUDE_TESTS)

#define l3_setup(...)

#endif // defined(L3_INCLUDE_TESTS)


@class L3Test;
typedef void(^L3TestStateBlock)(L3Test *self);

@class L3TestState;
@interface L3TestStatePrototype : NSObject

+(instancetype)statePrototypeWithProtocol:(Protocol *)stateProtocol setUpBlock:(L3TestStateBlock)setUpBlock;

-(L3TestState *)createState;

@end

@interface L3TestState : NSObject

@property (readonly) Protocol *stateProtocol;

@property (readonly) NSMutableDictionary *properties;

-(void)setUpWithTest:(L3Test *)test;
@property (readonly) L3TestStateBlock setUpBlock;

@end

L3_OVERLOADABLE L3TestStatePrototype *L3TestStatePrototypeDefine(Protocol *stateProtocol, L3TestStateBlock setUpBlock) {
	return [L3TestStatePrototype statePrototypeWithProtocol:stateProtocol setUpBlock:setUpBlock];
}

#endif // L3_TEST_STATE_H
