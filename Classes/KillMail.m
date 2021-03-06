//
//  KillMail.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 09.11.12.
//
//

#import "KillMail.h"

@implementation KillMailPilot

- (void) dealloc {
	[_allianceName release];
	[_characterName release];
	[_corporationName release];
	[_shipType release];
	[super dealloc];
}

@end

@implementation KillMailVictim
@end

@implementation KillMailAttacker

- (void) dealloc {
	[_weaponType release];
	[super dealloc];
}

@end

@implementation KillMailItem

- (void) dealloc {
	[_type release];
	[super dealloc];
}

@end

@implementation KillMail

- (id) initWithKillLogKill:(EVEKillLogKill*) kill {
	if (self = [super init]) {

		self.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID error:nil];
		self.killTime = kill.killTime;
		
		self.victim = [[[KillMailVictim alloc] init] autorelease];
		self.victim.allianceID = kill.victim.allianceID;
		self.victim.allianceName = kill.victim.allianceName;
		self.victim.characterID = kill.victim.characterID;
		self.victim.characterName = kill.victim.characterName;
		self.victim.corporationID = kill.victim.corporationID;
		self.victim.corporationName = kill.victim.corporationName;
		self.victim.shipType = [EVEDBInvType invTypeWithTypeID:kill.victim.shipTypeID error:nil];
		self.victim.damageTaken = kill.victim.damageTaken;
		
		self.attackers = [NSMutableArray array];
		for (EVEKillLogAttacker* item in kill.attackers) {
			KillMailAttacker* attacker = [[[KillMailAttacker alloc] init] autorelease];
			attacker.allianceID = item.allianceID;
			attacker.allianceName = item.allianceName;
			attacker.characterID = item.characterID;
			attacker.characterName = item.characterName;
			attacker.corporationID = item.corporationID;
			attacker.corporationName = item.corporationName;
			attacker.shipType = [EVEDBInvType invTypeWithTypeID:item.shipTypeID error:nil];
			attacker.damageDone = item.damageDone;
			attacker.weaponType = [EVEDBInvType invTypeWithTypeID:item.weaponTypeID error:nil];
			attacker.finalBlow = item.finalBlow;
			attacker.securityStatus = item.securityStatus;
			[self.attackers addObject:attacker];
		}
		
		[self.attackers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"damageDone" ascending:NO]]];
		
		NSMutableDictionary* containers = [NSMutableDictionary dictionary];
		
		for (NSString* slot in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystemSlots", @"droneBay", @"cargo"]) {
			NSMutableDictionary* container = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionary], @"dropped", [NSMutableDictionary dictionary], @"destroyed", nil];
			[containers setValue:container forKey:slot];
		}

		for (EVEKillLogItem* item in kill.items) {
			NSString* slot = nil;
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			
			if (item.flag >= EVEInventoryFlagNone) {
				if ([type.effectsDictionary valueForKey:@"12"])
					slot = @"hiSlots";
				else if ([type.effectsDictionary valueForKey:@"13"])
					slot = @"medSlots";
				else if ([type.effectsDictionary valueForKey:@"11"])
					slot = @"lowSlots";
				else if ([type.effectsDictionary valueForKey:@"2663"])
					slot = @"rigSlots";
				else if (type.group.categoryID == 32)
					slot = @"subsystemSlots";
			}
			if (!slot) {
				if (item.flag == EVEInventoryFlagDroneBay)
					slot = @"droneBay";
				else
					slot = @"cargo";
			}
			
			if (item.qtyDestroyed) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				NSMutableDictionary* container = [[containers valueForKey:slot] valueForKey:@"destroyed"];
				KillMailItem* destroyedItem = [container valueForKey:key];
				if (!destroyedItem) {
					destroyedItem = [[[KillMailItem alloc] init] autorelease];
					destroyedItem.type = type;
					destroyedItem.qty = item.qtyDestroyed;
					destroyedItem.destroyed = YES;
					[container setValue:destroyedItem forKey:key];
				}
				else
					destroyedItem.qty += item.qtyDestroyed;
			}
			if (item.qtyDropped) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				NSMutableDictionary* container = [[containers valueForKey:slot] valueForKey:@"dropped"];
				KillMailItem* droppedItem = [container valueForKey:key];
				if (!droppedItem) {
					droppedItem = [[[KillMailItem alloc] init] autorelease];
					droppedItem.type = type;
					droppedItem.qty = item.qtyDropped;
					droppedItem.destroyed = NO;
					[container setValue:droppedItem forKey:key];
				}
				else
					droppedItem.qty += item.qtyDropped;
			}
		}
		
		NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"destroyed" ascending:NO]];
		for (NSString* key in containers) {
			NSDictionary* container = [containers valueForKey:key];
			NSArray* dropped = [[container valueForKey:@"dropped"] allValues];
			NSArray* destroyed = [[container valueForKey:@"destroyed"] allValues];
			NSArray* items = [[destroyed arrayByAddingObjectsFromArray:dropped] sortedArrayUsingDescriptors:sortDescriptors];
			if (items.count > 0) {
				[self setValue:items forKey:key];
			}
		}
	}
	return self;
}

- (id) initWithKillNetLogEntry:(EVEKillNetLogEntry*) kill {
	if (self = [super init]) {
		
		self.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemName:kill.systemName error:nil];
		self.killTime = kill.timestamp;
		
		NSMutableDictionary* names = [NSMutableDictionary dictionary];
		
		self.victim = [[[KillMailVictim alloc] init] autorelease];
		self.victim.allianceName = kill.victimAllianceName;
		self.victim.characterName = kill.victimName;
		self.victim.corporationName = kill.victimCorpName;
		self.victim.shipType = [EVEDBInvType invTypeWithTypeID:kill.victimShipID error:nil];
		self.victim.damageTaken = kill.damageTaken;
		
		if (self.victim.allianceName.length > 0)
			[names setValue:@(0) forKey:self.victim.allianceName];
		if (self.victim.corporationName.length > 0)
			[names setValue:@(0) forKey:self.victim.corporationName];
		if (self.victim.characterName.length > 0)
			[names setValue:@(0) forKey:self.victim.characterName];
		if (names.count > 0) {
			EVECharacterID* charIDs = [EVECharacterID characterIDWithNames:[names allKeys] error:nil];
			for (EVECharacterIDItem* item in charIDs.characters)
				[names setValue:@(item.characterID) forKey:item.name];
		}
		
		if (self.victim.characterName.length > 0)
			self.victim.characterID = [[names valueForKey:self.victim.characterName] integerValue];
		if (self.victim.allianceName.length > 0)
			self.victim.allianceID = [[names valueForKey:self.victim.allianceName] integerValue];
		if (self.victim.corporationName.length > 0)
			self.victim.corporationID = [[names valueForKey:self.victim.corporationName] integerValue];
		
		self.attackers = [NSMutableArray array];
		for (EVEKillNetLogInvolved* item in kill.involved) {
			KillMailAttacker* attacker = [[[KillMailAttacker alloc] init] autorelease];
			attacker.allianceID = item.allianceID;
			attacker.allianceName = item.allianceName;
			attacker.characterID = item.characterID;
			attacker.characterName = item.characterName;
			attacker.corporationID = item.corporationID;
			attacker.corporationName = item.corporationName;
			attacker.shipType = [EVEDBInvType invTypeWithTypeID:item.shipTypeID error:nil];
			attacker.damageDone = item.damageDone;
			attacker.weaponType = [EVEDBInvType invTypeWithTypeID:item.weaponTypeID error:nil];
			attacker.finalBlow = item.finalBlow;
			attacker.securityStatus = item.securityStatus;
			[self.attackers addObject:attacker];
		}
		
		[self.attackers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"damageDone" ascending:NO]]];
		
		NSMutableDictionary* containers = [NSMutableDictionary dictionary];
		
		for (NSString* slot in @[@"hiSlots", @"medSlots", @"lowSlots", @"rigSlots", @"subsystemSlots", @"droneBay", @"cargo"]) {
			NSMutableDictionary* container = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionary], @"dropped", [NSMutableDictionary dictionary], @"destroyed", nil];
			[containers setValue:container forKey:slot];
		}
		
		for (EVEKillNetLogItem* item in [kill.droppedItems arrayByAddingObjectsFromArray:kill.destroyedItems]) {
			NSString* slot = nil;
			EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			
			if (item.itemSlot == 1 && [type.effectsDictionary valueForKey:@"12"])
				slot = @"hiSlots";
			else if (item.itemSlot == 2 && [type.effectsDictionary valueForKey:@"13"])
				slot = @"medSlots";
			else if (item.itemSlot == 3 && [type.effectsDictionary valueForKey:@"11"])
				slot = @"lowSlots";
			else if (item.itemSlot == 5 && [type.effectsDictionary valueForKey:@"2663"])
				slot = @"rigSlots";
			else if (item.itemSlot == 7 && type.group.categoryID == 32)
				slot = @"subsystemSlots";
			else if (item.itemSlot == 6)
				slot = @"droneBay";
			else
				slot = @"cargo";
			
			if (item.qtyDestroyed) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				NSMutableDictionary* container = [[containers valueForKey:slot] valueForKey:@"destroyed"];
				KillMailItem* destroyedItem = [container valueForKey:key];
				if (!destroyedItem) {
					destroyedItem = [[[KillMailItem alloc] init] autorelease];
					destroyedItem.type = type;
					destroyedItem.qty = item.qtyDestroyed;
					destroyedItem.destroyed = YES;
					[container setValue:destroyedItem forKey:key];
				}
				else
					destroyedItem.qty += item.qtyDestroyed;
			}
			if (item.qtyDropped) {
				NSString* key = [NSString stringWithFormat:@"%d", type.typeID];
				NSMutableDictionary* container = [[containers valueForKey:slot] valueForKey:@"dropped"];
				KillMailItem* droppedItem = [container valueForKey:key];
				if (!droppedItem) {
					droppedItem = [[[KillMailItem alloc] init] autorelease];
					droppedItem.type = type;
					droppedItem.qty = item.qtyDropped;
					droppedItem.destroyed = NO;
					[container setValue:droppedItem forKey:key];
				}
				else
					droppedItem.qty += item.qtyDropped;
			}
		}
		
		NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"destroyed" ascending:NO]];
		for (NSString* key in containers) {
			NSDictionary* container = [containers valueForKey:key];
			NSArray* dropped = [[container valueForKey:@"dropped"] allValues];
			NSArray* destroyed = [[container valueForKey:@"destroyed"] allValues];
			NSArray* items = [[destroyed arrayByAddingObjectsFromArray:dropped] sortedArrayUsingDescriptors:sortDescriptors];
			if (items.count > 0) {
				[self setValue:items forKey:key];
			}
		}
	}
	return self;
}

- (void) dealloc {
	[_hiSlots release];
	[_medSlots release];
	[_lowSlots release];
	[_rigSlots release];
	[_subsystemSlots release];
	[_droneBay release];
	[_cargo release];
	[_attackers release];
	[_victim release];
	[_solarSystem release];
	[_killTime release];
	[super dealloc];
}

@end
