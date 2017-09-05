//
//  FastCSVParser.h
//  CSVParser Test App
//
//  Created by Jakob Egger on 17. 5. 2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FastCSVParser : NSObject {
	NSData *data;
	const char *start, *end, *curr;
	NSMutableArray<NSString*> *warnings;
}
@property char separator;
@property char quote;
@property char escape;
@property char newline;

-(nonnull id)initWithData:(nonnull NSData*)someData;
-(nullable NSArray<NSString*>*)next;

@end
