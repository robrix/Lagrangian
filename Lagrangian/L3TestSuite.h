#ifndef L3_TEST_SUITE_H
#define L3_TEST_SUITE_H

#pragma clang diagnostic push
#pragma clang diagnostic ignore ("-Wvariadic-macros")
#pragma clang diagnostic ignore ("-Wdocumentation-unknown-command")
#import <XCTest/XCTestSuite.h>
#pragma clang diagnostic pop

#import <Lagrangian/L3SourceReference.h>

@class L3TestStatePrototype;

@interface L3TestSuite : XCTestSuite

/// Return bundle for the Mach-O executable containing \c address.
+(NSBundle *)bundleForExecutableWithAddress:(void(*)(void))address;

+(instancetype)suiteForExecutablePath:(NSString *)executablePath;
+(instancetype)suiteForFile:(NSString *)file inExecutableForAddress:(void(*)(void))address;

+(instancetype)suiteWithSourceReference:(id<L3SourceReference>)sourceReference;
-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference;

@property (readonly) id<L3SourceReference> sourceReference;

@property L3TestStatePrototype *statePrototype;

-(instancetype)suiteForFile:(NSString *)file;
-(instancetype)addSuite:(L3TestSuite *)suite;

@end

#endif // L3_TEST_SUITE_H
