#ifndef L3_TEST_H
#define L3_TEST_H

#pragma clang diagnostic push
#pragma clang diagnostic ignore ("-Wvariadic-macros")
#import <XCTest/XCTestSuite.h>
#pragma clang diagnostic pop

#import <Lagrangian/L3Defines.h>
#import <Lagrangian/L3Expectation.h>
#import <Lagrangian/L3SourceReference.h>

#pragma mark API

#define l3_test(...) \
	_l3_test_construct(__COUNTER__, __VA_ARGS__)

#if defined(L3_INCLUDE_TESTS)
#define _l3_test_construct(uid, ...) \
	L3_INLINE void _l3_test_function_name(uid) (L3Test *self); \
	L3_CONSTRUCTOR void _l3_test_constructor_name(uid) (void) { \
		L3TestSuite *suite = [L3TestSuite suiteForFile:@__FILE__ inExecutableForAddress:_l3_test_constructor_name(uid)]; \
		L3Test *test = L3TestDefine(@__FILE__, __LINE__, @#__VA_ARGS__, __VA_ARGS__, &_l3_test_function_name(uid)); \
		test.statePrototype = suite.statePrototype; \
		[suite addTest:test]; \
	} \
	L3_INLINE void _l3_test_function_name(uid) (L3Test *self)

#define _l3_test_constructor_name(uid) \
	metamacro_concat(L3TestConstructor, uid)

#define _l3_test_function_name(uid) \
	metamacro_concat(L3TestFunction, uid)

#else // defined(L3_INCLUDE_TESTS)

#define _l3_test_construct(uid, ...) \
	L3_UNUSABLE void metamacro_concat(metamacro_concat(L3, uid), UnusableTestFunction) (L3Test *self)

#endif // defined(L3_INCLUDE_TESTS)


typedef void (*L3TestFunction)(L3Test *self);

enum {
	L3AssertionFailedError
};

L3_EXTERN NSString * const L3ErrorDomain;

L3_EXTERN NSString * const L3TestErrorKey;
L3_EXTERN NSString * const L3ExpectationErrorKey;


@protocol L3TestVisitor;
@class L3TestStatePrototype;

@interface L3Test : XCTestSuite

+(instancetype)testWithSourceReference:(id<L3SourceReference>)sourceReference function:(L3TestFunction)function;
-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference function:(L3TestFunction)function;

@property (readonly) id<L3SourceReference> sourceReference;

@property (readonly) NSArray *expectations;
-(void)addExpectation:(id<L3Expectation>)expectation;

@property L3TestStatePrototype *statePrototype;

-(bool)testExpectation:(id<L3Expectation>)expectation withBlock:(id<L3TestResult>(^)(void))block;

@end


typedef void (*L3FunctionTestSubject)(void *, ...);
L3_EXTERN NSString *L3TestSymbolForFunction(L3FunctionTestSubject subject);
typedef id (^L3BlockTestSubject)();
L3_EXTERN L3FunctionTestSubject L3TestFunctionForBlock(L3BlockTestSubject subject);

L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, SEL subject, L3TestFunction function) {
	return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, NSStringFromSelector(subject)) function:function];
}

L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, const char *subject, L3TestFunction function) {
	return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, @(subject)) function:function];
}

L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, NSString *(*subject)(NSString *, NSDictionary *), L3TestFunction function) {
	return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, L3TestSymbolForFunction((L3FunctionTestSubject)subject)) function:function];
}

L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, id (^subject)(id), L3TestFunction function) {
	return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, L3TestSymbolForFunction((L3FunctionTestSubject)L3TestFunctionForBlock((L3BlockTestSubject)subject))) function:function];
}

/**
 Registers the type of the passed function as allowable as a test subject (i.e. the first parameter to \c l3_test).
 
 Note that clang C function overloading seems to require that the address of the function be taken explicitly, e.g. `l3_test(&sinf, ^{})`.
 
 \param functionSubject The function whose type should be valid as a test subject.
 */
#define l3_addTestSubjectTypeWithFunction(functionSubject) \
	L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, __typeof__(functionSubject) subject, L3TestFunction function) { \
		return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, L3TestSymbolForFunction((L3FunctionTestSubject)subject)) function:function]; \
	}

/**
 Registers the type of the passed block as allowable as a test subject (i.e. the first parameter to \c l3_test).
 
 \param blockSubject The block whose type should be valid as a test subject.
 */
#define l3_addTestSubjectTypeWithBlock(blockSubject) \
	L3_OVERLOADABLE L3Test *L3TestDefine(NSString *file, NSUInteger line, NSString *subjectSource, __typeof__(blockSubject) subject, L3TestFunction function) { \
		return [L3Test testWithSourceReference:L3SourceReferenceCreate(nil, file, line, subjectSource, L3TestSymbolForFunction((L3FunctionTestSubject)L3TestFunctionForBlock((L3BlockTestSubject)subject))) function:function]; \
	}

#endif // L3_TEST_H
