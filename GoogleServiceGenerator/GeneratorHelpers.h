//
//  GeneratorHelpers.h
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/18/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeneratorHelpers : NSObject

+ (NSString *)objcName:(NSString *)str
      shouldCapitalize:(BOOL)shouldCapitalize
    allowLeadingDigits:(BOOL)allowLeadingDigits;

@end
