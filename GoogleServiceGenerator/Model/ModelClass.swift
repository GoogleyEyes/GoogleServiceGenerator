//
//  ModelClass.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/5/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import Stencil

/**
*  Represents a schema given by an API's discovery document.
*/
class ModelClass: SourceFileGeneratable, CustomStringConvertible {
    var supertype: String
    var properties: [Property]
    var classDescription: String
    
    init(className: String, supertype: String, properties: [Property], description: String) {
        self.supertype = supertype
        self.properties = properties
        self.classDescription = description
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return classDescription.documentationString() + "\npublic struct \(name): \(supertype)"
    }
    
    override func generateSourceFileString() -> String {
        let propertiesStrings = properties.map { property -> [String: String] in
            return ["declaration": "\(property)", "initWithJSONMethodLine": property.initWithJSONMethodLine, "toJSONMethodLine": property.toJSONMethodLine]
        }
        let context = Context(dictionary: [
                "name": name,
                "supertype": supertype,
                "properties": propertiesStrings,
                "description": classDescription
            ])
        do {
            let template = try Template(named: "ModelClass.stencil")
            let rendered = try template.render(context)
            return rendered
        } catch {
            print("Failed to render template \(error) for class \(name)")
            return ""
        }
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
        let propertiesStrings = properties.map { property -> [String: String] in
            return ["declaration": "\(property)", "initWithJSONMethodLine": property.initWithJSONMethodLine, "toJSONMethodLine": property.toJSONMethodLine]
        }
        let type: String
        switch listType {
        case "GoogleObjectList": type = "GoogleObject"
        case "ListType": fallthrough
        default: type = "ObjectType"
        }
        let context = Context(dictionary: [
            "name": name,
            "listType": type,
            "properties": propertiesStrings,
            "itemType": itemType,
            "description": classDescription
            ])
        do {
            let template = try Template(named: "ModelListClass.stencil")
            let rendered = try template.render(context)
            return rendered
        } catch {
            print("Failed to render template \(error) for class \(name)")
            return ""
        }
    }
}
