//
//  FastCSVParser.m
//  CSVParser Test App
//
//  Created by Jakob Egger on 17. 5. 2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

#import "FastCSVParser.h"

@implementation FastCSVParser

-(nonnull id)initWithData:(nonnull NSData*)someData;
{
	if (self = [super init]) {
		data = [someData copy];
		start = curr = data.bytes;
		end = start + data.length;
		
		_separator = ',';
		_quote = '"';
		_escape = '"';
		_newline = '\n';
	}
	return self;
}


-(nullable NSArray<NSString*>*)next;
{
	if (curr >= end) return nil;
	
	NSMutableArray *line = [[NSMutableArray alloc] init];
	BOOL insideQuote = false;
	
	size_t currStrSize = 32;
	char *currStr = malloc(currStrSize);
	int currStrOffset = 0;

	while (curr < end) {
		if (insideQuote) {
			if (*curr == _escape && curr < end - 1 && (*(curr+1)==_quote || *(curr+1)==_escape)) {
				curr++;
			}
			else if (*curr == _quote) {
				insideQuote = false;
				curr++;
				continue;
			}
		}
		else if (*curr==_quote) {
			insideQuote = true;
			curr++;
			continue;
		}
		else if (*curr==_separator) {
			[line addObject:[[NSString alloc] initWithBytes:currStr length:currStrOffset encoding:NSUTF8StringEncoding]];
			currStrOffset = 0;
			curr++;
			continue;
		}
		else if (*curr==_newline) {
			curr++;
			break;
		}

		
		// check codepoint at curr
		int len;
		BOOL valid = false;
		if ((*curr & 0b10000000) == 0) {
			len = 1;
			valid = true;
		}
		else if ((*curr & 0b11000000) == 0b10000000) {
			len = 1;
			valid = false;
		}
		else if ((*curr & 0b11100000) == 0b11000000) {
			len = 2;
		}
		else if ((*curr & 0b11110000) == 0b11100000) {
			len = 3;
		}
		else if ((*curr & 0b11111000) == 0b11110000) {
			len = 4;
		}
		else {
			len = 1;
			valid = false;
		}
		if (len>1) {
			if (end-curr < len) {
				len = end-curr;
				valid = false;
			} else {
				valid = true;
				for (int i = 1; i < len; i++) {
					if ((*(curr+i) & 0b11000000) != 0b10000000) {
						valid = false;
						len = i;
					}
				}
			}
		}
		const char *src;
		int srclen;
		if (!valid) {
			src = "�";
			srclen = strlen(src);
		} else {
			src = curr;
			srclen = len;
		}
		if (currStrOffset + srclen > currStrSize) {
			currStrSize *= 2;
			currStr = reallocf(currStr, currStrSize);
		}
		for (int i=0; i<srclen; i++) {
			currStr[currStrOffset++] = *(src+i);
		}
		curr += len;
	}
	[line addObject:[[NSString alloc] initWithBytes:currStr length:currStrOffset encoding:NSUTF8StringEncoding]];
	free(currStr);
	return line;
}

@end
