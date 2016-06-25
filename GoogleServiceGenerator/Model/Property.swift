//
//  Property.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/26/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class Property: SourceFileGeneratable, CustomStringConvertible {
    var jsonName: String // used for ObjectMapper
    var type: String
    var optionality: OptionalityOnType
    var transformType: String?
    var defaultValue: String? {
        didSet {
            if defaultValue != nil {
                hasDefaultValue = true
            } else {
                hasDefaultValue = false
            }
        }
    }
    var required: Bool
    var docDescription: String?
    var isEnum: Bool
    var location: String?
    var hasDefaultValue: Bool
    
    init(nameFoundInJSONSchema jsonName: String, type: String, optionality: OptionalityOnType, transformType: String? = nil, defaultValue: String? = nil, required: Bool = false, description: String?, isEnum: Bool = false, location: String? = nil) {
        self.jsonName = jsonName
        self.type = type
        self.optionality = optionality
        self.transformType = transformType
        self.defaultValue = defaultValue
        if defaultValue == nil {
            hasDefaultValue = false
        } else {
            hasDefaultValue = true
            self.optionality = .NonOptional
        }
        self.required = required
        if required {
            self.optionality = .NonOptional
        }
        docDescription = description
        self.isEnum = isEnum
        self.location = location
        
        super.init()
        self.name = jsonName.objcName(shouldCapitalize: false) // edit jsonName to fit source file character restrictions

    }
    
    var description: String {
        return generateSourceFileString()
    }
    
    override func generateSourceFileString() -> String {
        var string = ""
        if let desc = docDescription {
            string += desc.documentationString()
            string.addNewLine(); string.addTab()
            string += "public var \(name): \(type)\(optionality.rawValue)"
        } else {
            string += "public var \(name): \(type)\(optionality.rawValue)"
        }
        
        if required {
            string += " // REQUIRED"
        }
        
        if defaultValue != nil {
            string += " = \(defaultValue!)"
        }
        
        return string
    }
    
    func namesAreNotEqual(one: Property, _ two: Property) -> Bool {
        return one.name != two.name
    }
}

func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name && lhs.type == rhs.type && lhs.optionality == rhs.optionality && lhs.defaultValue == rhs.defaultValue
}

enum OptionalityOnType: String {
    case Optional = "?"
    case NonOptional = ""
    case ImplicitlyUnwrappedOptional = "!"
}
