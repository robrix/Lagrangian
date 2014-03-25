//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import <XCTest/XCTest.h>
#import <Lagrangian/Lagrangian.h>

@interface L3TestStub : XCTestCase
@end

@implementation L3TestStub

+(id)defaultTestSuite {
	XCTestSuite *suite = [XCTestSuite testSuiteWithName:@"Lagrangian stub"];
	[suite addTestsEnumeratedBy:[L3TestSuite registeredSuites].allValues.objectEnumerator];
	return suite;
}

@end
