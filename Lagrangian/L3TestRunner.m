#import "L3Expectation.h"
#import "L3SourceReference.h"
#import "L3Test.h"
#import "L3TestSuite.h"
#import "L3TestRunner.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

NSString * const L3TestRunnerRunTestsOnLaunchEnvironmentVariableName = @"L3_RUN_TESTS_ON_LAUNCH";
NSString * const L3TestRunnerSubjectEnvironmentVariableName = @"L3_TEST_RUNNER_SUBJECT";


@interface L3TestStatistics : NSObject
@property NSDate *startDate;
@property NSDate *endDate;
@property unsigned long testCount;
@property unsigned long assertionFailureCount;
@property unsigned long exceptionCount;
@property NSTimeInterval duration;

-(void)addStatistics:(L3TestStatistics *)statistics;
@end

@interface L3TestRunner () <L3TestVisitor>

@property (readonly) NSOperationQueue *queue;
@property (readonly) L3TestStatistics *statistics;

-(void)runAtLaunch;

@end

@implementation L3TestRunner

+(bool)shouldRunTestsAtLaunch {
	return [[NSProcessInfo processInfo].environment[L3TestRunnerRunTestsOnLaunchEnvironmentVariableName] boolValue];
}

+(bool)isRunningInApplication {
	return
#if TARGET_OS_IPHONE
		([UIApplication class] != nil)
#else
		([NSApplication class] != nil)
#endif
	&&	[[NSBundle mainBundle].bundlePath.pathExtension isEqualToString:@"app"];
}

+(NSString *)subjectPath {
	NSString *path = [NSProcessInfo processInfo].environment[L3TestRunnerSubjectEnvironmentVariableName];
	if (!path && self.isRunningInApplication) {
		path = [NSBundle mainBundle].executablePath;
	}
	return path;
}


#pragma mark Constructors

L3_CONSTRUCTOR void L3TestRunnerLoader() {
	L3TestRunner *runner = [L3TestRunner new];
	
	if ([L3TestRunner shouldRunTestsAtLaunch]) {
		[runner runAtLaunch];
	}
}

-(instancetype)init {
	if ((self = [super init])) {
		_queue = [NSOperationQueue new];
		_queue.maxConcurrentOperationCount = 1;
		
		_statistics = [L3TestStatistics new];
	}
	return self;
}


#pragma mark Running

-(void)runAtLaunch {
	NSArray *(^registeredTests)(void) = ^{
		NSArray *tests = [[L3TestSuite registeredSuites] allValues];
		if ([self.class subjectPath]) {
			L3TestSuite *suite = [L3TestSuite registeredSuiteForFile:[self.class subjectPath]];
			if (suite)
				tests = @[suite];
		}
		return tests;
	};
	
	if ([self.class isRunningInApplication]) {
		NSString *notificationName;
		void(^terminate)(void);
#if TARGET_OS_IPHONE
		notificationName = UIApplicationDidFinishLaunchingNotification;
#else
		notificationName = NSApplicationDidFinishLaunchingNotification;
		terminate = ^{
			[[NSApplication sharedApplication] terminate:nil];
		};
#endif
		__block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:self.queue usingBlock:^(NSNotification *note) {
			
			[self enqueueTests:registeredTests()];
			
			[[NSNotificationCenter defaultCenter] removeObserver:observer name:notificationName object:nil];
			
			if (terminate) [self.queue addOperationWithBlock:terminate];
		}];
	} else {
		[self.queue addOperationWithBlock:^{
			[self enqueueTests:registeredTests()];
#if !TARGET_OS_IPHONE
			[self.queue addOperationWithBlock:^__attribute__((noreturn)) {
				exit(self.statistics.assertionFailureCount == 0);
			}];
#endif
		}];
	}
}

-(void)enqueueTests:(NSArray *)tests {
	for (L3Test *test in tests) {
		[self enqueueTest:test];
	}
}

-(void)enqueueTest:(L3Test *)test {
	NSParameterAssert(test != nil);
	[self.queue addOperationWithBlock:^{
		[self.statistics addStatistics:[test acceptVisitor:self parents:nil context:nil]];
	}];
}

-(bool)waitForTestsToComplete {
	[self.queue waitUntilAllOperationsAreFinished];
	return self.statistics.assertionFailureCount == 0;
}


#pragma mark L3TestVisitor

-(void)write:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2) {
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:arguments];
	fprintf(stdout, "%s", string.UTF8String);
	va_end(arguments);
}

-(NSString *)cardinalizeNoun:(NSString *)noun forCount:(NSInteger)count {
	return [NSString stringWithFormat:@"%li %@%@", (long)count, noun, count == 1? @"" : @"s"];
}

-(NSString *)formatStringAsTestName:(NSString *)string {
	NSMutableString *mutable = [string mutableCopy];
	[[NSRegularExpression regularExpressionWithPattern:@"[^\\w]+" options:NSRegularExpressionCaseInsensitive error:NULL] replaceMatchesInString:mutable options:NSMatchingWithTransparentBounds range:(NSRange){0, mutable.length} withTemplate:@"_"];
	return [mutable copy];
}

-(NSString *)caseNameWithSuiteName:(NSString *)suiteName assertivePhrase:(NSString *)phrase {
	return [NSString stringWithFormat:@"-[%@ %@]", suiteName, [self formatStringAsTestName:phrase]];
}

-(id)visitTest:(L3Test *)test parents:(NSArray *)parents lazyChildren:(NSArray *)lazyChildren context:(id)context {
	L3TestStatistics *statistics = [L3TestStatistics new];
	NSString *suiteName = [self formatStringAsTestName:[test.sourceReference.subject description]];
	[self write:@"Test Suite '%@' started at %@\n", suiteName, statistics.startDate];
	[self write:@"\n"];
	
	[test setUp];
	
	[test run:^(id<L3Expectation> expectation, id<L3TestResult> result) {
		NSDate *testCaseStart = [NSDate date];
		statistics.testCount++;
		NSString *caseName = [self caseNameWithSuiteName:suiteName assertivePhrase:result.hypothesisString];
		[self write:@"Test Case '%@' started.\n", caseName];
		if (!result.wasMet) {
			[test self];
			id<L3SourceReference> reference = result.subjectReference;
			[self write:@"%@:%lu: error: %@ : %@\n", reference.file, (unsigned long)reference.line, caseName, result.observationString];
			
			statistics.assertionFailureCount++;
			if (result.exception != nil)
				statistics.exceptionCount++;
		}
		NSTimeInterval interval = -[testCaseStart timeIntervalSinceNow];
		statistics.duration += interval;
		[self write:@"Test Case '%@' %@ (%.3f seconds).\n", caseName, result.wasMet? @"passed" : @"failed", interval];
		[self write:@"\n"];
	}];
	
	for (id(^lazyChild)() in lazyChildren) {
		[statistics addStatistics:lazyChild()];
	}
	
	[test tearDown];
	
	statistics.endDate = [NSDate date];
	
	[self write:@"Test Suite '%@' finished at %@.\n", suiteName, statistics.endDate];
	[self write:@"Executed %@, with %@ (%lu unexpected) in %.3f (%.3f) seconds.\n", [self cardinalizeNoun:@"test" forCount:statistics.testCount], [self cardinalizeNoun:@"failure" forCount:statistics.assertionFailureCount], statistics.exceptionCount, statistics.duration, [statistics.endDate timeIntervalSinceDate:statistics.startDate]];
	[self write:@"\n"];
	
	return statistics;
}

@end

@implementation L3TestStatistics

-(instancetype)init {
	if ((self = [super init])) {
		_startDate = [NSDate date];
	}
	return self;
}

-(void)addStatistics:(L3TestStatistics *)statistics {
	self.testCount += statistics.testCount;
	self.assertionFailureCount += statistics.assertionFailureCount;
	self.exceptionCount += statistics.exceptionCount;
	self.duration += statistics.duration;
}

@end
