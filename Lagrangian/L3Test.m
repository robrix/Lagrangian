#import "L3Block.h"
#import "L3Test.h"
#import "Lagrangian.h"
#import <dlfcn.h>


NSString * const L3ErrorDomain = @"com.antitypical.lagrangian";

NSString * const L3ExpectationErrorKey = @"L3ExpectationErrorKey";
NSString * const L3TestErrorKey = @"L3TestErrorKey";

l3_setup(L3Test, (L3Test *test)) {}

@interface L3ExpectationTestCase : XCTestCase

+(instancetype)testCaseWithExpectation:(id<L3Expectation>)expectation result:(id<L3TestResult>)result inTest:(L3Test *)test;

@end

@interface L3Test ()

@property (readonly) L3TestFunction function;

@property (readonly) NSMutableArray *mutableExpectations;

@property (copy) L3TestExpectationBlock expectationCallback;

@property L3TestState *state;

@end

@implementation L3Test

+(instancetype)testWithSourceReference:(id<L3SourceReference>)sourceReference function:(L3TestFunction)function {
	return [[self alloc] initWithSourceReference:sourceReference function:function];
}

-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference function:(L3TestFunction)function {
	if ((self = [super initWithName:[sourceReference.subject description]])) {
		_sourceReference = sourceReference;
		
		_function = function;
		
		_mutableExpectations = [NSMutableArray new];
	}
	return self;
}


-(NSArray *)expectations {
	return self.mutableExpectations;
}

-(void)addExpectation:(id<L3Expectation>)expectation {
	[self.mutableExpectations addObject:expectation];
}


-(void)setUp {
	self.state = [self.statePrototype createState];
	[self.state setUpWithTest:self];
	
	if (self.function) self.function(self);
}

-(void)tearDown {
	self.state = nil;
}

-(void)run:(L3TestExpectationBlock)expectationCallback {
	self.expectationCallback = expectationCallback;
	if (self.function) self.function(self);
}

-(void)expectation:(id<L3Expectation>)expectation producedResult:(id<L3TestResult>)result {
	if (self.expectationCallback) self.expectationCallback(expectation, result);
	else {
		[self addTest:[L3ExpectationTestCase testCaseWithExpectation:expectation result:result inTest:self]];
	}
}

-(void)failWithException:(NSException *)exception {
	[self expectation:nil producedResult:L3TestResultCreateWithException(exception)];
}


#pragma mark NSObject

-(NSString *)description {
	return [NSString stringWithFormat:@"%@ (%@)", super.description, self.sourceReference];
}

@end


NSString *L3TestSymbolForFunction(L3FunctionTestSubject subject) {
	NSString *symbol;
	Dl_info info = {0};
	if (dladdr((void *)subject, &info)) {
		symbol = @(info.dli_sname);
	}
	return symbol;
}

l3_addTestSubjectTypeWithFunction(L3TestSymbolForFunction)
l3_test(&L3TestSymbolForFunction) {
	NSString *symbol = L3TestSymbolForFunction((L3FunctionTestSubject)L3TestSymbolForFunction);
	l3_expect(symbol).to.equal(@"L3TestSymbolForFunction");
}

L3BlockFunction L3TestFunctionForBlock(L3BlockTestSubject subject) {
	return L3BlockGetFunction(subject);
}


@implementation L3ExpectationTestCase {
	id<L3Expectation> _expectation;
	id<L3TestResult> _result;
	__weak L3Test *_test;
}

+(instancetype)testCaseWithExpectation:(id<L3Expectation>)expectation result:(id<L3TestResult>)result inTest:(L3Test *)test {
	return [[self alloc] initWithExpectation:expectation result:result inTest:test];
}

-(instancetype)initWithExpectation:(id<L3Expectation>)expectation result:(id<L3TestResult>)result inTest:(L3Test *)test {
	if ((self = [super init])) {
		_expectation = expectation;
		_result = result;
		_test = test;
	}
	return self;
}


+(XCTest *)defaultTestSuite {
	return nil;
}


#pragma mark Formatting

-(NSString *)cardinalizeNoun:(NSString *)noun forCount:(NSInteger)count {
	return [NSString stringWithFormat:@"%li %@%@", (long)count, noun, count == 1? @"" : @"s"];
}

-(NSString *)formatStringAsTestName:(NSString *)string {
	NSMutableString *mutable = [string mutableCopy];
	[[NSRegularExpression regularExpressionWithPattern:@"[^A-Za-z0-9_$]+" options:NSRegularExpressionCaseInsensitive error:NULL] replaceMatchesInString:mutable options:NSMatchingWithTransparentBounds range:(NSRange){0, mutable.length} withTemplate:@"_"];
	return [mutable copy];
}

-(NSString *)caseNameWithSuiteName:(NSString *)suiteName assertivePhrase:(NSString *)phrase {
	return [NSString stringWithFormat:@"-[%@ %@]", suiteName, [self formatStringAsTestName:phrase]];
}


#pragma mark XCTest

-(NSString *)name {
	return [self caseNameWithSuiteName:[self formatStringAsTestName:_test.name] assertivePhrase:_expectation.assertivePhrase];
}

-(void)invokeTest {
	if (!_result.wasMet) {
		[self recordFailureWithDescription:_result.observationString inFile:_expectation.subjectReference.file atLine:_expectation.subjectReference.line expected:_result.exception != nil];
	}
}

@end
