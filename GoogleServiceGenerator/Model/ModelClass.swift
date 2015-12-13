//
//  ModelClass.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/5/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

/**
*  Represents a schema given by an API's discovery document.
*/
class ModelClass: SourceFileGeneratable, CustomStringConvertible {
    var superclass: String
    var properties: [Property]
    
    init(className: String, superclass: String, properties: [Property]) {
        self.superclass = superclass
        self.properties = properties
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return "public class \(name): \(superclass)"
    }
    override func generateSourceFileString() -> String {
        // 1) class declaration (with "{")
        var string = "public class \(name): \(superclass) {"
        string.addNewLine(); string.addTab()
        // 2) property declarations
        for property in properties {
            string += "\(property)"
            string.addNewLine(); string.addTab()
        }
        string.addNewLine(); string.addTab() // line break
        // 3) mappable init?()
        string += "public required init?(_ map: Map) {"
        string.addNewLine(); string.addNewLine(); string.addTab()
        string += "}"
        // line break
        string.addNewLine(); string.addNewLine(); string.addTab()
        // 4) mapping(map:)
        string += "public func mapping(map: Map) {"
        string.addNewLine(); string.addTab(); string.addTab()
        for property in properties {
            if property.type == "NSURL" || property.type == "NSDate" {
                let type = Types.transformType(forType: Types(rawValue: property.type))!.rawValue
                string += "\(property.name) <- (map[\"\(property.jsonName)\"], \(type)())"
            } else {
                string += "\(property.name) <- map[\"\(property.jsonName)\"]"
            }
            string.addNewLine(); string.addTab()
            if property != properties[properties.endIndex - 1] {
                string.addTab()
            } else {
                string += "}"
            }
        }
        // 5) closing bracket
        string.addNewLine()
        string += "}"
        return string
    }
}

class ModelListClass: SourceFileGeneratable, CustomStringConvertible{
    var properties: [Property]
    var itemType: String
    
    init(className: String, properties: [Property], itemType: String, itemsPropertyDescription: String) {
        self.properties = [Property(nameFoundInJSONSchema: "items", type: "[Type]", optionality: .ImplicitlyUnwrappedOptional, description: itemsPropertyDescription)]
        self.properties.appendContentsOf(properties)
        self.itemType = itemType
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return "public class \(name): GoogleObjectList"
    }
    
    override func generateSourceFileString() -> String {
        // 1) class declaration (with "{")
        var string = "public class \(name): GoogleObjectList {"
        string.addNewLine(); string.addTab()
        
        // 2) property declarations
        string += "public typealias Type = \(itemType)"
        string.addNewLine(); string.addTab()
        for property in properties {
            string += "\(property)"
            string.addNewLine(); string.addTab()
        }
        string.addNewLine(); string.addTab() // line break
        
        // 3) mappable init?()
        string += "public required init?(_ map: Map) {"
        string.addNewLine(); string.addNewLine(); string.addTab()
        string += "}"
        // line break
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 4) mapping(map:)
        string += "public func mapping(map: Map) {"
        string.addNewLine(); string.addTab(); string.addTab()
        for property in properties {
            if property.transformType != nil {
                string += "\(property.name) <- (map[\"\(property.jsonName)\"], \(property.transformType!)())"
            } else {
                string += "\(property.name) <- map[\"\(property.jsonName)\"]"
            }
            string.addNewLine(); string.addTab()
            if property != properties[properties.endIndex - 1] {
                string.addTab()
            }
        }
        string += "}"
        string.addNewLine(); string.addTab()
        
        // 5) arrayLiteral init()
        string += "public required init(arrayLiteral elements: Type...) {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "items = elements"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 6) Generate (forin)
        string += "public typealias Generator = IndexingGenerator<[Type]>"
        string.addNewLine(); string.addNewLine(); string.addTab()
        string += "public func generate() -> Generator {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "let objects = items as [Type]"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "return objects.generate()"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 7) subscript
        string += "public subscript(position: Int) -> Type {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "return items[position]"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine()
        
        // 5) closing bracket
        string += "}"
        return string
    }
}