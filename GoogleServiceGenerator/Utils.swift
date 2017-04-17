//
//  GeneratorHelpers.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/21/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

extension String {
    func objcName(shouldCapitalize: Bool, allowLeadingDigits: Bool = false) -> String {
        var vetted = GeneratorHelpers.objcName(self, shouldCapitalize: shouldCapitalize, allowLeadingDigits: allowLeadingDigits)
        if vetted == "default" {
            vetted = "defaultValue"
        }
        return vetted!
    }
    
    static func objcName(components: [String], shouldCapitalize: Bool, allowLeadingDigits: Bool = false) -> String {
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
    
    mutating func addNewLine() {
        self += String.newLine
    }
    mutating func addTab() {
        self += String.tab
    }
    
    func makeCamelCaseLowerCase() -> String {
        let strInitial = self
        var characters: [Character] = []
        for char in strInitial.characters {
            if char == strInitial.characters.first {
                let charStr = String(char)
                let lowercase = charStr.lowercased()
                let finalChar = lowercase.characters.first
                characters.append(finalChar!)
            } else {
                characters.append(char)
            }
        }
        return String(characters)
    }
    
    func documentationString() -> String {
        var final = ""
        if self.components(separatedBy: "\n").count != 1 {
            final += "/**"
            for component in self.components(separatedBy: "\n") {
                final.addNewLine(); final.addTab()
                final += component
            }
            final += "*/"
        } else {
            final += "/// \(self)"
        }
        return final
    }
}
