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

+(NSBundle *)bundleForImagePath:(NSString *)imagePath {
	imagePath = imagePath.stringByResolvingSymlinksInPath;
	NSBundle *bundle = nil;
	for (NSBundle *each in [[NSBundle allBundles] arrayByAddingObjectsFromArray:[NSBundle allFrameworks]]) {
		NSString *currentBundlePath = each.executablePath.stringByResolvingSymlinksInPath;
		if ([currentBundlePath isEqual:imagePath]) {
			bundle = each;
			break;
		}
	}
	return bundle;
}

+(NSBundle *)bundleForImageWithAddress:(void(*)(void))address {
	return [self bundleForImagePath:[self pathForImageWithAddress:address]];
}


+(instancetype)suiteForImageWithAddress:(void(*)(void))address {
	return [self testSuiteForBundlePath:[self bundleForImageWithAddress:address].bundlePath];
}

+(instancetype)suiteForFile:(NSString *)file inImageForAddress:(void(*)(void))address {
	return [[self suiteForImageWithAddress:address] suiteForFile:file];
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


+(NSMutableDictionary *)registeredSuites {
	static NSMutableDictionary *registeredSuites = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		registeredSuites = [NSMutableDictionary new];
	});
	return registeredSuites;
}

+(instancetype)defaultTestSuite {
	static L3TestSuite *defaultTestSuite;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		defaultTestSuite = [[self alloc] initWithName:@"All Tests"];
	});
	return defaultTestSuite;
}

+(instancetype)testSuiteForBundlePath:(NSString *)bundlePath {
	L3TestSuite *suite = bundlePath == nil?
		self.defaultTestSuite
	:	self.registeredSuites[bundlePath];
	if (suite == nil) {
		suite = self.registeredSuites[bundlePath] = [[self alloc] initWithName:bundlePath.lastPathComponent];
		[[self defaultTestSuite] addTest:suite];
	}
	return suite;
}


-(instancetype)initWithName:(NSString *)name {
	if ((self = [super initWithName:name])) {
		_suitesByFile = [NSMutableDictionary new];
	}
	return self;
}


-(instancetype)suiteForFile:(NSString *)file {
	L3TestSuite *suite = _suitesByFile[file];
	return suite ? suite : [self addSuite:[[self.class alloc] initWithSourceReference:L3SourceReferenceCreate(@0, file, 0, nil, file.lastPathComponent.stringByDeletingPathExtension)]];
}

-(instancetype)addSuite:(L3TestSuite *)suite {
	[self addTest:suite];
	return _suitesByFile[suite.sourceReference.file] = suite;
}

@end
