//
//  GeneratorHelpers.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/21/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

extension String {
    func objcName(shouldCapitalize shouldCapitalize: Bool, allowLeadingDigits: Bool = false) -> String {
        return GeneratorHelpers.objcName(self, shouldCapitalize: shouldCapitalize, allowLeadingDigits: allowLeadingDigits)
    }
    
    static func objcName(components components: [String], shouldCapitalize: Bool, allowLeadingDigits: Bool = false) -> String {
        var finalString: String = ""
        for component in components {
            if component == components.first {
                finalString += component.objcName(shouldCapitalize: shouldCapitalize, allowLeadingDigits: allowLeadingDigits)
            } else {
                finalString += component.objcName(shouldCapitalize: true, allowLeadingDigits: true)
            }
        }
        return finalString
    }
    
    static var tab: String {
        return "\t"
    }
    static var newLine: String {
        return "\n"
    }
    
    mutating func addNewLine() -> String {
        self += String.newLine
        return self
    }
    mutating func addTab() -> String {
        self += String.tab
        return self
    }
    
    func makeCamelCaseLowerCase() -> String {
        let strInitial = self
        var characters: [Character] = []
        for char in strInitial.characters {
            if char == strInitial.characters.first {
                let charStr = String(char)
                let lowercase = charStr.lowercaseString
                let finalChar = lowercase.characters.first
                characters.append(finalChar!)
            } else {
                characters.append(char)
            }
        }
        return String(characters)
    }
}
