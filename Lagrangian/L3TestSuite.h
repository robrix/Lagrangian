#ifndef L3_TEST_SUITE_H
#define L3_TEST_SUITE_H

#import <XCTest/XCTest.h>
#import <Lagrangian/L3SourceReference.h>

@class L3TestStatePrototype;

@interface L3TestSuite : XCTestSuite

+(instancetype)suiteForFile:(NSString *)file inImageForAddress:(void(*)(void))address;

+(instancetype)suiteWithSourceReference:(id<L3SourceReference>)sourceReference;
-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference;

@property (readonly) id<L3SourceReference> sourceReference;

@property L3TestStatePrototype *statePrototype;

-(instancetype)suiteForFile:(NSString *)file;
-(instancetype)addSuite:(L3TestSuite *)suite forFile:(NSString *)file;

@end

#endif // L3_TEST_SUITE_H
