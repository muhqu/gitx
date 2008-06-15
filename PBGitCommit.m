//
//  PBGitCommit.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommit.h"


@implementation PBGitCommit

@synthesize sha, repository, subject, author;

- initWithRepository:(PBGitRepository*) repo andSha:(NSString*) newSha
{
	self.repository = repo;
	self.sha = newSha;
	return self;
}

- (NSString*) details
{
	NSFileHandle* handle = [self.repository handleForCommand:[@"show --pretty=raw " stringByAppendingString:self.sha]];
	NSString* details = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding: NSASCIIStringEncoding];
	return  details;
}

- (PBGitTree*) tree
{
	NSLog(@"Tree called!");
	return [PBGitTree rootForCommit: self];
}

- (NSArray *) children
{
	NSLog(@"Children aangeroepen");
	return [NSArray arrayWithObjects:self, self, nil];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}
@end