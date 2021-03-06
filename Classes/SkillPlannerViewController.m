//
//  SkillPlannerViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerViewController.h"
#import "SkillCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "EVEAccount.h"
#import "UIAlertView+Error.h"
#import "SkillPlan.h"
#import "TrainingQueue.h"
#import "UIImageView+GIF.h"
#import "NSString+TimeLeft.h"
#import "ItemViewController.h"
#import "ItemCellView.h"
#import "Globals.h"
#import "SkillPlannerImportViewController.h"
#import "BrowserViewController.h"

#define ActionButtonLevel1 NSLocalizedString(@"Train to Level 1", nil)
#define ActionButtonLevel2 NSLocalizedString(@"Train to Level 2", nil)
#define ActionButtonLevel3 NSLocalizedString(@"Train to Level 3", nil)
#define ActionButtonLevel4 NSLocalizedString(@"Train to Level 4", nil)
#define ActionButtonLevel5 NSLocalizedString(@"Train to Level 5", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface SkillPlannerViewController(Private)

- (void) loadData;
- (void) didAddSkill:(NSNotification*) notification;
- (void) didChangeSkill:(NSNotification*) notification;
- (void) didRemoveSkill:(NSNotification*) notification;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) reloadTrainingTime;

@end

@implementation SkillPlannerViewController
@synthesize skillsTableView;
@synthesize trainingTimeLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidRemoveSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[skillsTableView release];
	[skillPlan release];
	[trainingTimeLabel release];
	[modifiedIndexPath release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Skill Planner", nil);
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Do any additional setup after loading the view from its nib.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddSkill:) name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeSkill:) name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveSkill:) name:NotificationSkillPlanDidRemoveSkill object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadData];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidAddSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidChangeSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSkillPlanDidRemoveSkill object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[self setTrainingTimeLabel:nil];
    [super viewDidUnload];
	self.skillsTableView = nil;
	[skillPlan release];
	skillPlan = nil;
	[modifiedIndexPath release];
	modifiedIndexPath = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[skillsTableView setEditing:editing animated:animated];
	//NSArray* clearRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:skillPlan.skills.count inSection:0]];
	NSIndexSet* section = [NSIndexSet indexSetWithIndex:1];
	if (editing)
		[skillsTableView insertSections:section withRowAnimation:UITableViewRowAnimationFade];
	else {
		[skillsTableView deleteSections:section withRowAnimation:UITableViewRowAnimationFade];
		[skillPlan save];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.editing ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? skillPlan.skills.count : 3;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
		NSString *cellIdentifier = @"ItemCellView";
		
		ItemCellView *cell = (ItemCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [ItemCellView cellWithNibName:@"ItemCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		if (indexPath.row == 0) {
			cell.titleLabel.text = NSLocalizedString(@"Clear skill plan", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon77_12.png"];
		}
		else if (indexPath.row == 1) {
			cell.titleLabel.text = NSLocalizedString(@"Import skill plan from EVEMon", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"EVEMonLogoBlue.png"];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Importing tutorial", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		}
		return cell;
	}
	else {
		static NSString *cellIdentifier = @"SkillCellView";
		
		SkillCellView *cell = (SkillCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [SkillCellView cellWithNibName:@"SkillCellView" bundle:nil reuseIdentifier:cellIdentifier];
		}
		
		EVEAccount* account = [EVEAccount currentAccount];
		
		EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:indexPath.row];
		EVESkillQueueItem* trainedSkill = account.skillQueue.skillQueue.count > 0 ? [account.skillQueue.skillQueue objectAtIndex:0] : nil;
		
		BOOL isActive = trainedSkill.typeID == skill.typeID;

		cell.iconImageView.image = [UIImage imageNamed:(isActive ? @"Icons/icon50_12.png" : @"Icons/icon50_13.png")];
		NSString* levelImageName = [NSString stringWithFormat:@"level_%d%d%d.gif", skill.currentLevel, skill.requiredLevel, isActive];
		NSString* levelImagePath = [[NSBundle mainBundle] pathForResource:levelImageName ofType:nil];
		if (levelImagePath)
			[cell.levelImageView setGIFImageWithContentsOfURL:[NSURL fileURLWithPath:levelImagePath]];
		else
			[cell.levelImageView setImage:nil];
		
		EVEDBDgmTypeAttribute *attribute = [[skill attributesDictionary] valueForKey:@"275"];
		cell.skillLabel.text = [NSString stringWithFormat:@"%@ (x%d)", skill.typeName, (int) attribute.value];
		cell.skillPointsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SP: %@", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:skill.requiredSP] numberStyle:NSNumberFormatterDecimalStyle]];
		cell.levelLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Level %d", nil), skill.requiredLevel];
		NSTimeInterval trainingTime = (skill.requiredSP - skill.currentSP) / [skillPlan.characterAttributes skillpointsPerSecondForSkill:skill];
		cell.remainingLabel.text = [NSString stringWithTimeLeft:trainingTime];
		return cell;
	}
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0;
}

/*- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 return proposedDestinationIndexPath;
 }*/

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSObject *objectToMove = [[skillPlan.skills objectAtIndex:fromIndexPath.row] retain];
    [skillPlan.skills removeObjectAtIndex:fromIndexPath.row];
    [skillPlan.skills insertObject:objectToMove atIndex:toIndexPath.row];
    [objectToMove release];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[tableView beginUpdates];
		[skillPlan removeSkill:[skillPlan.skills objectAtIndex:indexPath.row]];
		[tableView endUpdates];
		//[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self reloadTrainingTime];
		[skillPlan save];
	}
}

#pragma mark -
#pragma mark Table view delegate


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) {
		EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:indexPath.row];
		if (self.editing) {
			[modifiedIndexPath release];
			modifiedIndexPath = [indexPath retain];
			UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																	 delegate:self
															cancelButtonTitle:nil
													   destructiveButtonTitle:nil
															otherButtonTitles:nil];
			if (skill.currentLevel < 1)
				[actionSheet addButtonWithTitle:ActionButtonLevel1];
			if (skill.currentLevel < 2)
				[actionSheet addButtonWithTitle:ActionButtonLevel2];
			if (skill.currentLevel < 3)
				[actionSheet addButtonWithTitle:ActionButtonLevel3];
			if (skill.currentLevel < 4)
				[actionSheet addButtonWithTitle:ActionButtonLevel4];
			if (skill.currentLevel < 5)
				[actionSheet addButtonWithTitle:ActionButtonLevel5];
			
			[actionSheet addButtonWithTitle:ActionButtonCancel];
			actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
			
			[actionSheet showFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView animated:YES];
			[actionSheet release];
		}
		else {
			ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
			
			controller.type = skill;
			[controller setActivePage:ItemViewControllerActivePageInfo];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
				[self presentModalViewController:navController animated:YES];
				[navController release];
			}
			else
				[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	}
	else {
		if (indexPath.row == 0) {
			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Clear skill plan?", nil)
																message:@""
															   delegate:self
													  cancelButtonTitle:NSLocalizedString(@"No", nil)
													  otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
			[alertView show];
			[alertView autorelease];
		}
		else if (indexPath.row == 1) {
			SkillPlannerImportViewController* controller = [[SkillPlannerImportViewController alloc] initWithNibName:@"SkillPlannerImportViewController" bundle:nil];
			controller.delegate = self;
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = UIBarStyleBlackOpaque;

			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navController animated:YES];
			[navController release];
			[controller release];
		}
		else {
			BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
			NSString* path = [[NSBundle mainBundle] pathForResource:@"ImportingTutorial/index" ofType:@"html"];
			controller.title = NSLocalizedString(@"Importing tutorial", nil);
			controller.startPageURL = [NSURL fileURLWithPath:path];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				controller.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:controller animated:YES];
			[controller release];
		}
	}
}

#pragma mark UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonCancel])
		return;
	
	NSInteger requiredLevel = 0;
	if ([button isEqualToString:ActionButtonLevel1])
		requiredLevel = 1;
	else if ([button isEqualToString:ActionButtonLevel2])
		requiredLevel = 2;
	else if ([button isEqualToString:ActionButtonLevel3])
		requiredLevel = 3;
	else if ([button isEqualToString:ActionButtonLevel4])
		requiredLevel = 4;
	else if ([button isEqualToString:ActionButtonLevel5])
		requiredLevel = 5;
	
	EVEDBInvTypeRequiredSkill* skill = [skillPlan.skills objectAtIndex:modifiedIndexPath.row];
	
	EVEDBInvTypeRequiredSkill* skillToDelete = nil;
	EVEDBInvTypeRequiredSkill* skillToInsert = nil;
	
	for (EVEDBInvTypeRequiredSkill* requiredSkill in skillPlan.skills) {
		if (requiredSkill.typeID == skill.typeID) {
			if (requiredSkill.requiredLevel > requiredLevel) {
				if (!skillToDelete)
					skillToDelete = requiredSkill;
				else if (skillToDelete.requiredLevel > requiredSkill.requiredLevel)
					skillToDelete = requiredSkill;
			}
			else if (requiredSkill.requiredLevel < requiredLevel) {
				if (!skillToInsert)
					skillToInsert = requiredSkill;
				else if (skillToInsert.requiredLevel < requiredSkill.requiredLevel)
					skillToInsert = requiredSkill;
			}
		}
	}
	
	if (skillToDelete) {
		[skillPlan removeSkill:skillToDelete];
	}
	else if (skillToInsert) {
		NSInteger index = [skillPlan.skills indexOfObject:skillToInsert];
		[skillsTableView beginUpdates];
		EVECharacterSheetSkill *characterSkill = [skillPlan.characterSkills valueForKey:[NSString stringWithFormat:@"%d", skill.typeID]];
		for (NSInteger level = skillToInsert.requiredLevel + 1; level <= requiredLevel; level++) {
			if (characterSkill.level >= skill.requiredLevel)
				return;

			EVEDBInvTypeRequiredSkill* requiredSkill = [EVEDBInvTypeRequiredSkill invTypeWithTypeID:skill.typeID error:nil];
			requiredSkill.requiredLevel = level;
			requiredSkill.currentLevel = characterSkill.level;
			float sp = [requiredSkill skillpointsAtLevel:level - 1];
			requiredSkill.currentSP = MAX(sp, characterSkill.skillpoints);
			[skillPlan.skills insertObject:requiredSkill atIndex:++index];
			[skillsTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
		[skillPlan resetTrainingTime];
		[skillsTableView endUpdates];
		[self reloadTrainingTime];
	}
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[skillPlan clear];
		[skillPlan save];
		[self loadData];
	}
}

#pragma mark SkillPlannerImportViewControllerDelegate
- (void) skillPlannerImportViewController:(SkillPlannerImportViewController*) controller didSelectSkillPlan:(SkillPlan*) aSkillPlan {
	[[EVEAccount currentAccount] setSkillPlan:aSkillPlan];
	[aSkillPlan save];
	[self loadData];
}

@end


@implementation SkillPlannerViewController(Private)

- (void) loadData {
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlannerViewController+Load" name:NSLocalizedString(@"Loading Skill Plan", nil)];
	__block SkillPlan* skillPlanTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		EVEAccount *account = [EVEAccount currentAccount];
		if (!account) {
			[pool release];
			return;
		}
		skillPlanTmp = [account.skillPlan retain];
		
		NSError *error = nil;
		account.skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID error:&error];
		operation.progress = 0.5;
		[skillPlanTmp trainingTime];
		operation.progress = 1.0;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[skillPlan release];
		if (![operation isCancelled]) {
			skillPlan = skillPlanTmp;

			[skillsTableView reloadData];
			[self reloadTrainingTime];
		}
		else {
			skillPlan = nil;
			[skillPlanTmp release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didAddSkill:(NSNotification*) notification {
	if (notification.object == skillPlan) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadTrainingTime) object:nil];
		[self performSelector:@selector(reloadTrainingTime) withObject:nil afterDelay:0];
//		[self reloadTrainingTime];
		[skillsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:skillPlan.skills.count - 1 inSection:0]]
							   withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didChangeSkill:(NSNotification*) notification {
	if (notification.object == skillPlan) {
		[self reloadTrainingTime];
		EVEDBInvTypeRequiredSkill* skill = [notification.userInfo valueForKey:@"skill"];
		[skillsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[skillPlan.skills indexOfObject:skill] inSection:0]]
							   withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didRemoveSkill:(NSNotification*) notification {
	if (notification.object == skillPlan) {
		[self reloadTrainingTime];
		NSIndexSet* indexesSet = [notification.userInfo valueForKey:@"indexes"];
		NSMutableArray* indexes = [NSMutableArray array];
		[indexesSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[indexes addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
		}];
		[skillsTableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account)
		[self.navigationController popToRootViewControllerAnimated:YES];
	else {
		[skillPlan release];
		skillPlan = nil;
		[self loadData];
	}
}

- (void) reloadTrainingTime {
	trainingTimeLabel.text = skillPlan.skills.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Training time: %@", nil), [NSString stringWithTimeLeft:skillPlan.trainingTime]] : NSLocalizedString(@"Skill plan is empty", nil);
}

@end
