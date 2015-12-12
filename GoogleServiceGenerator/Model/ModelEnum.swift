//
//  ModelEnum.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/6/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class ModelEnum: SourceFileGeneratable, CustomStringConvertible {
    var type: String
    var cases: [String] // each case printed verbatim -- need to include quotes in string values
    var caseNames: [String] // where case [caseNames[x]] = [cases[x]]
    
    init(name: String, type: String, cases: [String], caseNames: [String]) {
        self.type = type
        self.cases = cases
        self.caseNames = caseNames
        
        super.init()
        self.name = name
    }
    
    var description: String {
        return "public enum \(name): \(type)"
    }
    
    override func generateSourceFileString() -> String {
        // 1) enum declaration
        var string = "public enum \(name): \(type) {"
        string.addNewLine()
        string.addTab()
        
        // 2) cases
        for eachCase in cases {
            let index = Int((cases.indexOf(eachCase)?.toIntMax())!)
            string += "case \(caseNames[index]) = \(eachCase)"
            string.addNewLine()
            if eachCase != cases[cases.endIndex - 1] {
                string.addTab()
            }
        }
        
        // 3) closing bracket
        return string + "}"
    }
}

class ScopesEnum: SourceFileGeneratable, CustomStringConvertible {
    var values: [String]
    private var keys: [String]
    
    init(serviceName: String, values: [String]) {
        self.keys = values.map({ (value) -> String in
            let endOfURL = value.componentsSeparatedByString("/").last!
            var endComponents = endOfURL.componentsSeparatedByString(".")
            if endComponents[0].caseInsensitiveCompare(serviceName) == .OrderedSame {
                endComponents.removeAtIndex(0)
                if endComponents == [] {
                    endComponents.insert(serviceName, atIndex: 0)
                }
            }
            return String.objcName(components: endComponents, shouldCapitalize: true)
        })
        self.values = values.map({ (raw) -> String in
            return "\"\(raw)\""
        })
        
        super.init()
        self.name = "\(serviceName)OAuthScopes"
    }
    
    override func generateSourceFileString() -> String {
        // 1) enum declaration
        var string = "public enum \(name): String {"
        string.addNewLine()
        string.addTab()
        
        // 2) cases
        for eachCase in values {
            let index = Int((values.indexOf(eachCase)?.toIntMax())!)
            string += "case \(keys[index]) = \(eachCase)"
            string.addNewLine()
            let finalIndex = values.endIndex - 1
            if eachCase != values[finalIndex] {
                string.addTab()
            }
        }
        
        // 3) closing bracket
        return string + "}"
    }
    
    var description: String {
        return "public enum \(name) String"
    }
}
