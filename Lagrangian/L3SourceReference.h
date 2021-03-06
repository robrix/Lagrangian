#ifndef L3_SOURCE_REFERENCE_H
#define L3_SOURCE_REFERENCE_H

#import <Foundation/Foundation.h>
#import <Lagrangian/L3Defines.h>


@protocol L3SourceReference <NSObject, NSCopying>

@property (readonly) id identifier;

@property (readonly) NSString *file;
@property (readonly) NSUInteger line;

@property (readonly) NSString *subjectSource;
@property (readonly) id subject;

@end


#define l3_source_reference(...) \
	L3SourceReferenceCreate(@(__COUNTER__), @(__FILE__), __LINE__, @(#__VA_ARGS__), ^{ return L3Box(__VA_ARGS__); })

/**
 Creates a reference to a given source location, optionally including the subject of the reference and its source.
 
 @param identifier Delete me.
 @param file The file being referred to, most often @(__FILE__).
 @param line The line being referred to, most often __LINE__.
 @param subjectSource The source code of the subject of the reference. Can be nil.
 @param subjectBlock The subject of the reference (wrapped in a block). Can be nil.
 */
L3_EXTERN id<L3SourceReference> L3SourceReferenceCreateLazy(id identifier, NSString *file, NSUInteger line, NSString *subjectSource, id(^subjectBlock)(void));

L3_OVERLOADABLE id<L3SourceReference> L3SourceReferenceCreate(id identifier, NSString *file, NSUInteger line, NSString *subjectSource, id(^subjectBlock)(void)) {
	return L3SourceReferenceCreateLazy(identifier, file, line, subjectSource, subjectBlock);
}

L3_OVERLOADABLE id<L3SourceReference> L3SourceReferenceCreate(id identifier, NSString *file, NSUInteger line, NSString *subjectSource, id subject) {
	return L3SourceReferenceCreateLazy(identifier, file, line, subjectSource, ^{ return subject; });
}


#endif // L3_SOURCE_REFERENCE_H
