#import "L3SourceReference.h"

@interface L3SourceReference : NSObject <L3SourceReference>
@end

@implementation L3SourceReference {
	id (^_subjectBlock)(void);
}

#pragma mark Constructors

-(instancetype)initWithIdentifier:(id)identifier file:(NSString *)file line:(NSUInteger)line subjectSource:(NSString *)subjectSource subjectBlock:(id(^)(void))subjectBlock {
	if ((self = [super init])) {
		_identifier = identifier;
		
		_file = [file copy];
		_line = line;
		
		_subjectSource = [subjectSource copy];
		_subjectBlock = [subjectBlock copy];
	}
	return self;
}


#pragma mark L3SourceReference

@synthesize
	identifier = _identifier,
	file = _file,
	line = _line,

	subjectSource = _subjectSource,
	subject = _subject;

-(id)subject {
	if (_subjectBlock) {
		@try {
			_subject = _subjectBlock();
		}
		@finally {
			_subjectBlock = nil;
		}
	}
	return _subject;
}


#pragma mark NSCopying

-(instancetype)copyWithZone:(NSZone *)zone {
	return self;
}


#pragma mark NSObject

-(NSString *)description {
	return self.subject?
		[NSString stringWithFormat:@"%@ @ %@:%lu (%@ = %@)", super.description, self.file, (unsigned long)self.line, self.subjectSource, self.subject]
	:	[NSString stringWithFormat:@"%@ @ %@:%lu", super.description, self.file, (unsigned long)self.line];
}

@end


id<L3SourceReference> L3SourceReferenceCreateLazy(id identifier, NSString *file, NSUInteger line, NSString *subjectSource, id(^subjectBlock)(void)) {
	return [[L3SourceReference alloc] initWithIdentifier:identifier file:file line:line subjectSource:subjectSource subjectBlock:subjectBlock];
}
