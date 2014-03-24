//  Copyright (c) 2014 Rob Rix. All rights reserved.

#import <XCTest/XCTest.h>
#import <Lagrangian/L3SourceReference.h>

@class L3TestStatePrototype;

@interface L3TestSuite : XCTestSuite

+(NSDictionary *)registeredSuites;

+(instancetype)registeredSuiteForFile:(NSString *)file;

+(instancetype)suiteForFile:(NSString *)file inImageForAddress:(void(*)(void))address;

+(instancetype)suiteWithSourceReference:(id<L3SourceReference>)sourceReference;
-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference;

@property (readonly) id<L3SourceReference> sourceReference;

@property L3TestStatePrototype *statePrototype;

@end
