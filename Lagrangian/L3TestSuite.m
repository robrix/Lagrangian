#import "L3TestSuite.h"
#import "L3Test.h"
#import "L3SourceReference.h"
#import <dlfcn.h>

@implementation L3TestSuite {
	NSMutableDictionary *_suitesByFile;
}

+(NSString *)pathForImageWithAddress:(void(*)(void))address {
	NSString *path = nil;
	Dl_info info = {0};
	if (dladdr((void *)address, &info)) {
		path = @(info.dli_fname);
	}
	return path;
}

static void sampleAddress(void) {}

l3_test(@selector(pathForImageWithAddress:)) {
	NSString *pathForAddress = [L3TestSuite pathForImageWithAddress:sampleAddress];
	NSBundle *bundle = [NSBundle bundleForClass:[L3TestSuite class]];
	NSString *executablePathOfSameBundle = bundle.executablePath.stringByResolvingSymlinksInPath;
	l3_expect(pathForAddress).to.equal(executablePathOfSameBundle);
}

+(NSString *)bundlePathWithImagePath:(NSString *)imagePath {
	imagePath = imagePath.stringByResolvingSymlinksInPath;
	NSString *bundlePath = imagePath;
	for (NSBundle *bundle in [[NSBundle allBundles] arrayByAddingObjectsFromArray:[NSBundle allFrameworks]]) {
		NSString *currentBundlePath = bundle.executablePath.stringByResolvingSymlinksInPath;
		if ([currentBundlePath isEqual:imagePath]) {
			bundlePath = bundle.bundlePath;
			break;
		}
	}
	return bundlePath;
}

+(instancetype)suiteForImageWithAddress:(void(*)(void))address {
	return [self testSuiteForBundlePath:[self bundlePathWithImagePath:[self pathForImageWithAddress:address]]];
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
	if ((self = [self initWithName:sourceReference.subject])) {
		_sourceReference = sourceReference;
	}
	return self;
}


-(instancetype)initWithName:(NSString *)name {
	if ((self = [super initWithName:name])) {
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

@end


@interface L3TestSuiteLoader : XCTestCase
@end

@implementation L3TestSuiteLoader

+(id)defaultTestSuite {
	XCTestSuite *suite = [XCTestSuite testSuiteWithName:@"L3TestSuiteLoader"];
	[suite addTestsEnumeratedBy:[[L3TestSuite registeredSuites].allValues objectEnumerator]];
	return suite;
}

@end
