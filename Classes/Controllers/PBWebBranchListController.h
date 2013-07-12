//
//  PBWebBranchListController.h
//  GitX
//
//  Created by Mathias Leppich on 03.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBWebController.h"

#import "PBGitCommit.h"
#import "PBGitHistoryController.h"
#import "PBRefContextDelegate.h"

@class PBGitSHA;

@interface PBWebBranchListController : PBWebController {
	IBOutlet PBGitHistoryController* historyController;
	IBOutlet id<PBRefContextDelegate> contextMenuDelegate;
    
	PBGitSHA* currentSha;
    
    NSString * versus;
}

@property (nonatomic,retain) NSString * versus;

- (void) changeContentTo: (PBGitCommit *) commit;
- (void) sendKey: (NSString*) key;

@end
