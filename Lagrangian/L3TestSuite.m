#import "L3TestSuite.h"
#import "L3Test.h"
#import "L3SourceReference.h"
#import <dlfcn.h>

@implementation L3TestSuite {
	NSMutableDictionary *_suitesByFile;
}

+(NSMutableDictionary *)mutableRegisteredSuites {
	static NSMutableDictionary *suites = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		suites = [NSMutableDictionary new];
	});
	return suites;
}

+(NSDictionary *)registeredSuites {
	return self.mutableRegisteredSuites;
}


+(instancetype)registeredSuiteForFile:(NSString *)file {
	return self.mutableRegisteredSuites[file];
}


static inline NSString *L3PathForImageWithAddress(void(*address)(void)) {
	NSString *path = nil;
	Dl_info info = {0};
	if (dladdr((void *)address, &info)) {
		path = @(info.dli_fname);
	}
	return path;
}

+(instancetype)suiteForImageWithAddress:(void(*)(void))address {
	NSString *file = L3PathForImageWithAddress(address);
	L3TestSuite *suite = self.mutableRegisteredSuites[file];
	return suite ? suite : (self.mutableRegisteredSuites[file] = [self suiteWithSourceReference:L3SourceReferenceCreate(@0, file, 0, nil, file.lastPathComponent)]);
}

+(instancetype)suiteForFile:(NSString *)file inImageForAddress:(void(*)(void))address {
	L3TestSuite *imageSuite = [self suiteForImageWithAddress:address];
	L3TestSuite *suite = [imageSuite suiteForFile:file];
	return suite ? suite : [imageSuite addSuite:[self suiteWithSourceReference:L3SourceReferenceCreate(@0, file, 0, nil, [file.lastPathComponent stringByDeletingPathExtension])] forFile:file];
}


+(instancetype)suiteWithSourceReference:(id<L3SourceReference>)sourceReference {
	return [[self alloc] initWithSourceReference:sourceReference];
}

-(instancetype)initWithSourceReference:(id<L3SourceReference>)sourceReference {
	if ((self = [super initWithName:sourceReference.subject])) {
		_sourceReference = sourceReference;
		
		_suitesByFile = [NSMutableDictionary new];
	}
	return self;
}


-(instancetype)suiteForFile:(NSString *)file {
	return _suitesByFile[file];
}

-(instancetype)addSuite:(L3TestSuite *)suite forFile:(NSString *)file {
	[self addTest:suite];
	return _suitesByFile[file] = suite;
}


#pragma mark XCTestSuite

-(NSString *)name {
	return super.name;
}

@end
