//
//  EVEAssetListItem+AssetsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EVEAssetListItem+AssetsViewController.h"
#import <objc/runtime.h>

@implementation EVEAssetListItem (AssetsViewController)

- (EVEDBInvType*) type {
	EVEDBInvType* type = objc_getAssociatedObject(self, @"type");
	return type;
}

- (void) setType:(EVEDBInvType *)type {
	objc_setAssociatedObject(self, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVELocationsItem*) location {
	EVELocationsItem* location = objc_getAssociatedObject(self, @"location");
	return location;
}

- (void) setLocation:(EVELocationsItem *)location {
	objc_setAssociatedObject(self, @"location", location, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) characterName {
	NSString* characterName = objc_getAssociatedObject(self, @"characterName");
	return characterName;
}

- (void) setCharacterName:(NSString *)characterName {
	objc_setAssociatedObject(self, @"characterName", characterName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) name {
	NSString* name = objc_getAssociatedObject(self, @"name");
	if (!name)
		name = self.type.typeName;
	NSString* characterName = objc_getAssociatedObject(self, @"characterName");
	
	NSMutableString* string;
	if (quantity > 1)
		string = [NSMutableString stringWithFormat:@"%@ (x%d)", name, quantity];
	else if (contents.count == 1)
		string = [NSMutableString stringWithFormat:@"%@ (1 item)", name];
	else if (contents.count > 1)
		string = [NSMutableString stringWithFormat:@"%@ (%d items)", name, contents.count];
	else
		string = [NSMutableString stringWithString:name];
	
	if (characterName)
		[string appendFormat:@" (%@)", characterName];
	return string;
}

- (void) setName:(NSString *)name {
	objc_setAssociatedObject(self, @"name", name, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
