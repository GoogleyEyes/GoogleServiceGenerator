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
    var classDescription: String
    
    init(className: String, superclass: String, properties: [Property], description: String) {
        self.superclass = superclass
        self.properties = properties
        self.classDescription = description
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return classDescription.documentationString() + "\npublic class \(name): \(superclass)"
    }
    override func generateSourceFileString() -> String {
        // 1) class declaration (with "{")
        var string = classDescription.documentationString()
        string.addNewLine()
        string += "public class \(name): \(superclass) {"
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
        // 3) init()
        string += "public init() {"
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
            }
        }
        string += "}"
        // 5) closing bracket
        string.addNewLine()
        string += "}"
        return string
    }
}

class ModelListClass: SourceFileGeneratable, CustomStringConvertible{
    var properties: [Property]
    var itemType: String
    var listType: String
    var classDescription: String
    
    init(className: String, properties: [Property], itemType: String, itemsPropertyDescription: String?, listType: String, classDescription: String) {
//        self.properties = [Property(nameFoundInJSONSchema: "items", type: "[Type]", optionality: .ImplicitlyUnwrappedOptional, description: itemsPropertyDescription)]
        self.properties = properties
        self.itemType = itemType
        self.listType = listType
        self.classDescription = classDescription
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return classDescription.documentationString() + "\npublic class \(name): \(listType)"
    }
    
    override func generateSourceFileString() -> String {
        // 1) class declaration (with "{")
        var string = classDescription.documentationString()
        string.addNewLine()
        string += "public class \(name): \(listType) {"
        string.addNewLine(); string.addTab()
        
        // 2) property declarations
//        string += "public typealias Type = \(itemType)"
//        string.addNewLine(); string.addTab()
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
        
        // 3) init()
        string += "public init() {"
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
        string += "public required init(arrayLiteral elements: \(itemType)...) {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "items = elements"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 6) Generate (forin)
        string += "public typealias Generator = IndexingGenerator<[\(itemType)]>"
        string.addNewLine(); string.addNewLine(); string.addTab()
        string += "public func generate() -> Generator {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "let objects = items as [\(itemType)]"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "return objects.generate()"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 7) subscript
        string += "public subscript(position: Int) -> \(itemType) {"
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