//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import <XCTest/XCTest.h>
#import <Lagrangian/L3TestRunner.h>

@interface L3XCTest : XCTest
@end

@implementation L3XCTest

-(Class)testRunClass {
	return [XCTestRun class];
}

-(void)performTest:(XCTestRun *)run {
	L3TestRunner *runner = [L3TestRunner new];
	[runner runAtLaunch];
	[runner waitForTestsToComplete];
}

@end


@interface L3TestStub : XCTestCase
@end

@implementation L3TestStub

+(id)defaultTestSuite {
	XCTestSuite *suite = [XCTestSuite testSuiteWithName:@"Lagrangian stub"];
	L3XCTest *test = [[L3XCTest alloc] init];
	
	[suite addTest:test];
	
	return suite;
}

@end
