//
//  GeneratorHelpers.m
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/18/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

#import "GeneratorHelpers.h"

@implementation GeneratorHelpers

+ (NSString *)objcName:(NSString *)str
      shouldCapitalize:(BOOL)shouldCapitalize
    allowLeadingDigits:(BOOL)allowLeadingDigits {
    // Cache the character sets because this is done a lot...
    static NSCharacterSet *letterSet = nil;
    if (!letterSet) {
        // Just want a-zA-Z
        NSMutableCharacterSet *setBuilder =
        [NSMutableCharacterSet characterSetWithRange:NSMakeRange('a', 26)];
        [setBuilder addCharactersInRange:NSMakeRange('A', 26)];
        // Use immutable versions for speed in our checks.
        letterSet = [setBuilder copy];
    }
    static NSCharacterSet *letterNumSet = nil;
    if (!letterNumSet) {
        // Add 0-9 to our letterSet.
        NSMutableCharacterSet *setBuilder = [letterSet mutableCopy];
        [setBuilder addCharactersInRange:NSMakeRange('0', 10)];
        // Use immutable versions for speed in our checks.
        letterNumSet = [setBuilder copy];
    }
    
    if ([str length] == 0) {
        return @"";
    }
    
    // Do the transform...
    
    NSMutableString *worker = [NSMutableString string];
    
    BOOL isNewWord = shouldCapitalize;
    
    // If it doesn't start with a letter, put 'x' on the front.
    if (!allowLeadingDigits
        && ![letterSet characterIsMember:[str characterAtIndex:0]]) {
        [worker appendString:(isNewWord ? @"X" : @"x")];
        isNewWord = NO;
    }
    
    for (NSUInteger len = [str length], idx = 0; idx < len; ++idx ) {
        unichar curChar = [str characterAtIndex:idx];
        if ([letterNumSet characterIsMember:curChar]) {
            NSString *curCharStr = [NSString stringWithFormat:@"%C", curChar];
            if (isNewWord) {
                curCharStr = [curCharStr uppercaseString];
                isNewWord = NO;
            }
            [worker appendString:curCharStr];
        } else {
            isNewWord = YES;
        }
        
    }
    
    return worker;
}

@end
