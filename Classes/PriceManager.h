//
//  PriceManager.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEDBInvType;
@class EVEC0rporationFaction;
@interface PriceManager : NSObject {
	EVEC0rporationFaction* faction;
@private
	NSMutableDictionary* prices;
}
@property (nonatomic, retain) EVEC0rporationFaction* faction;

- (float) priceWithType:(EVEDBInvType*) type;
- (NSDictionary*) pricesWithTypes:(NSArray*) types;

@end
