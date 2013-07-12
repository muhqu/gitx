//
//  PBWebBranchListController.m
//  GitX
//
//  Created by Mathias Leppich on 03.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PBWebBranchListController.h"
#import "PBGitDefaults.h"
#import "PBGitSHA.h"
#import "PBGitRepository.h"


@implementation PBWebBranchListController

@synthesize versus;

- (void) awakeFromNib
{
	startFile = @"branchlist";
	repository = historyController.repository;
	[super awakeFromNib];
	[historyController addObserver:self forKeyPath:@"webCommit" options:0 context:@"ChangedCommit"];
}

- (void)closeView
{
	[[self script] setValue:nil forKey:@"commit"];
	[historyController removeObserver:self forKeyPath:@"webCommit"];
    
	[super closeView];
}

- (void) didLoad
{
	currentSha = nil;
	[self changeContentTo: historyController.webCommit];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(__bridge NSString *)context isEqualToString:@"ChangedCommit"])
		[self changeContentTo:historyController.webCommit];
    else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) changeVersus:(NSString *)newVersus {
    if (![newVersus isEqualToString:self.versus]) {
        NSLog(@"versus old: %@     new: %@", self.versus, newVersus);
        self.versus = newVersus;
        [self changeContentTo:historyController.webCommit];
    }
}

- (void) changeRef:(NSString *)refName {
    NSLog(@"change to ref: %@", refName);
    PBGitRef * ref = [[historyController repository] refForName:refName];
    PBGitCommit * revCommit = [[historyController repository] commitForRef:ref];
    [historyController selectCommit:[revCommit sha]];
}

- (NSInteger) numberOfRevsBetween:(NSString *)refA and:(NSString *)refB {
    NSString * refRange = [[NSString alloc] initWithFormat:@"%@..%@", refA, refB];
    NSArray * args = [[NSArray alloc] initWithObjects:@"rev-list", @"--count", refRange, nil];
    NSString * output = [repository outputForArguments:args];
    return [output integerValue];
}

- (void) changeContentTo: (PBGitCommit *) commit {
	if (commit == nil || !finishedLoading)
		return;
    
    NSDate * start = [[NSDate alloc] init];
    
    PBGitRepository * rep = [historyController repository];
    
    PBGitRevSpecifier * headRef = [rep headRef];
    NSArray * branches = [commit refs];
    
    NSMutableString * debug = [NSMutableString stringWithFormat:@"head: %@ commit: %@  branch(s): %@ \n\n",
                        [[headRef ref] shortName],
                        [commit shortName],
                        branches];
    
    
    NSString * localValue = @"local branches";
    NSMutableArray * versusList = [NSMutableArray array];

    if ([rep hasRemotes]) {
        [versusList addObject:[NSArray arrayWithObjects:localValue, [self.versus isEqualToString:localValue]?@"active":@"", nil]];
    }
    NSMutableArray * listOfRevSpecifier = [NSMutableArray array];
    for (NSString * remote in [rep remotes]) {
        NSString * value = [NSString stringWithFormat:@"remote %@", remote];
        [versusList addObject:[NSArray arrayWithObjects:value, [self.versus isEqualToString:value]?@"active":@"", nil]];
        if ([self.versus isEqualToString:value]) {
            for (PBGitRevSpecifier *rev in [[historyController repository] branches]) {
                PBGitRef * ref = [rev ref];
                if ([rev isSimpleRef] && [ref isRemoteBranch] && [[ref remoteName] isEqualToString:remote]) {
                    NSLog(@"rev: %@", rev);
                    [listOfRevSpecifier addObject:rev];
                }
            }
        }
    }
    if ([listOfRevSpecifier count] == 0) {
        for (PBGitRevSpecifier *rev in [[historyController repository] branches]) {
            if ([rev isSimpleRef] && [[rev ref] isBranch]) {
                [listOfRevSpecifier addObject:rev];
            }
        }
    }
    NSString * againstTitle = [commit shortName];
    PBGitRef * selectedRef = [[rep currentBranch] ref];
    for (PBGitRef * ref in [commit refs]) {
        if ([ref isEqualToRef:selectedRef]) {
            againstTitle = [ref shortName];
            break;
        }
    }
    if ([againstTitle isEqualToString:[commit shortName]]) {
        for (PBGitRef * ref in [commit refs]) {
            againstTitle = [ref shortName];
            break;
        }
    }
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)commit.timestamp];
    NSString * dateFormated = [NSDateFormatter localizedStringFromDate:date
                                                             dateStyle:NSDateFormatterLongStyle
                                                             timeStyle:NSDateFormatterNoStyle];
    NSString * dttmFormated = [NSDateFormatter localizedStringFromDate:date
                                                             dateStyle:NSDateFormatterMediumStyle
                                                             timeStyle:NSDateFormatterMediumStyle];

    NSArray * against = [NSArray arrayWithObjects:againstTitle, commit, dateFormated, dttmFormated, nil];
    
    NSMutableArray * branchList = [NSMutableArray array];
    
    NSDate * dateUntilHot = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24)]; // last 24 hours
    NSDate * dateUntilFresh = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*7)]; // last week
    NSDate * dateUntilStale = [NSDate dateWithTimeIntervalSinceNow:(-1*60*60*24*7*8)]; // last 2 month
    
    NSString * againstRef = [[commit sha] string];//[[rep headRef] simpleRef];
    for (PBGitRevSpecifier *rev in listOfRevSpecifier) {
        PBGitCommit * revCommit = [[historyController repository] commitForRef:[rev ref]];
        NSDate * date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)revCommit.timestamp];
        NSString * dateFormated = [NSDateFormatter localizedStringFromDate:date
                                                                 dateStyle:NSDateFormatterLongStyle
                                                                 timeStyle:NSDateFormatterNoStyle];
        NSString * dttmFormated = [NSDateFormatter localizedStringFromDate:date
                                                                 dateStyle:NSDateFormatterMediumStyle
                                                                 timeStyle:NSDateFormatterMediumStyle];
        
        // hot, fresh, stale, old
        NSString * freshness = [date isGreaterThan:dateUntilHot] ?  @"hot"
        : [date isGreaterThan:dateUntilFresh] ?  @"fresh"
        : [date isGreaterThan:dateUntilStale] ?  @"stale"
        : @"old";

        // NSNumber * behind = [NSNumber numberWithInt:0];
        NSNumber * behind = [NSNumber numberWithInteger:[self numberOfRevsBetween:[rev simpleRef] and:againstRef]];
        // NSNumber * ahead = [NSNumber numberWithInt:0];
        NSNumber * ahead = [NSNumber numberWithInteger:[self numberOfRevsBetween:againstRef and:[rev simpleRef]]];
        [branchList addObject:[NSArray arrayWithObjects:[rev simpleRef],
                               [rev description],
                               behind,
                               ahead,
                               revCommit,
                               dateFormated,
                               dttmFormated,
                               freshness,
                               nil]];
    }
    
    NSLog(@"%@", [debug description]);
    
    NSArray *arguments = [NSArray arrayWithObjects:against, versusList, branchList, nil];
    
    NSTimeInterval timeBeforeScript = [start timeIntervalSinceNow];
    [[self script] callWebScriptMethod:@"loadBranchList" withArguments: arguments];
    
	currentSha = [commit sha];
    
    NSTimeInterval timeAfterScript = [start timeIntervalSinceNow];
    NSLog(@"time after script: %f", timeAfterScript);
    /*
    NSBlockOperation * loadBranchBehindsAndAheads = [NSBlockOperation blockOperationWithBlock:^(void) {
        for (NSArray * item in branchList) {
            NSString * simpleRef = [item objectAtIndex:0];
            NSLog(@"item simpleRef: %@", simpleRef);
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperation:loadBranchBehindsAndAheads];
     */
}



@end
