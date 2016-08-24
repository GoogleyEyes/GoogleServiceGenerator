//
//  SchemaToModelClassTransformer.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/17/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import GoogleAPIs

class SchemaToModelClassTransformer {
    var serviceName: String = Generator.sharedInstance.serviceName
    
    func modelClassFromSchema(schemaName: String, schema: DiscoveryJSONSchema) -> ModelClass {
        // 1) class name
        let className = serviceName + schemaName
        // 2) properties
        let properties = schema.properties != nil ? propertiesFromSchemaProperties(schema.properties, resourceName: schemaName, className: className) : []
        // 3) superclass
        var superclass: String
        if schema.properties?["kind"] != nil {
            if schema.properties?["kind"]?.defaultValue != nil {
                superclass = "GoogleObject"
            } else {
                superclass = "ObjectType"
            }
        } else {
            superclass = "ObjectType"
        }
        if let overrideSuperclass = OverrideFileManager.overrideModelClass(className: className)?.type {
            superclass = overrideSuperclass
        }
        // 4) description
        let description: String
        if let desc = schema.schemaDescription {
            description = desc
        } else {
            description = "The \(schemaName) model type for use with the \(serviceName) API"
        }
        // 5) put it all together
        return ModelClass(className: className, superclass: superclass, properties: properties, description: description)
    }
    
    func modelListClassFromSchema(schemaName: String, schema: DiscoveryJSONSchema) -> ModelListClass {
        // 1) class name
        let className = serviceName + schemaName
        // 2a) list type
        var listType: String
        if schema.properties?["kind"] != nil {
            listType = "GoogleObjectList"
        } else {
            listType = "ListType"
        }
        if let overrideListType = OverrideFileManager.overrideModelClass(className: className)?.type {
            listType = overrideListType
        }
        // 2b) item type
        let itemType = serviceName + schema.properties["items"]!.items.xRef!
        // 3) properties
        var properties = propertiesFromSchemaProperties(schema.properties, resourceName: "", className: className)
//        let itemProperties = weedOutItemsProperties(properties)
//        for property in itemProperties {
//            if property.type != "[Type]" {
//                properties.removeAtIndex(properties.indexOf(property)!)
//            }
//        }
        // 4) items description
        let itemsDescription = schema.properties["items"]!.schemaDescription
        // 5) description
        let description: String
        if let desc = schema.schemaDescription {
            description = desc
        } else {
            description = "The \(schemaName) model type for use with the \(serviceName) API"
        }
        // 6) put it all together
        return ModelListClass(className: className, properties: properties, itemType: itemType, itemsPropertyDescription: itemsDescription, listType: listType, classDescription: description)
    }
    
    private func weedOutItemsProperties(array: [Property]) -> [Property] {
        var itemProperties: [Property] = []
        for property in array {
            if property.name == "items" {
                itemProperties.append(property)
            }
        }
        return itemProperties
    }
    
    // For those model classes not specifically conforming to GoogleObject
    func subModelClassFromSchema(schemaName: String, resourceName: String, schema: DiscoveryJSONSchema) -> ModelClass {
        // 1) class name
        var className = serviceName + resourceName.objcName(shouldCapitalize: true) + schemaName
        if schema.type == "array" {
            if className.characters.last == "s" {
                className = String(className.characters.dropLast())
            }
        }
        // 2) properties
        var properties: [Property] = []
        if schema.properties != nil {
            properties = propertiesFromSchemaProperties(schema.properties, resourceName: resourceName, className: className)
        } else if schema.items.type == "object" && schema.items.properties != nil {
            properties = propertiesFromSchemaProperties(schema.items.properties, resourceName: resourceName, className: className)
        }
        // 3) description
        let description = "The \(schemaName) subtype of the \(resourceName.objcName(shouldCapitalize: true)) model type for use with the \(serviceName) API"
        // 4) put it all together
        return ModelClass(className: className, superclass: "ObjectType", properties: properties, description: description)
    }
    
    func subModelClassForArrayValueTypeObjectFromSchema(schemaName: String, resourceName: String, schema: DiscoveryJSONSchema) -> ModelClass {
        // 1) class name
        let className = serviceName + resourceName.objcName(shouldCapitalize: true) + schemaName
        // 2) properties
        var properties: [Property] = []
        properties = propertiesFromSchemaProperties(schema.items.properties, resourceName: resourceName, className: className)
        // 3) description
        let description = "The \(schemaName) subtype of the \(resourceName.objcName(shouldCapitalize: true)) model type for use with the \(serviceName) API"
        // 4) put it all together
        return ModelClass(className: className, superclass: "ObjectType", properties: properties, description: description)
    }
    
    func generateProperty(forName name: String, info: DiscoveryJSONSchema, resourceName: String) -> Property {
        // 1) property type
        var propertyType = ""
        // 2) isEnum
        var isEnum: Bool = false
        if info.enumValues != nil {
            propertyType = serviceName + resourceName.objcName(shouldCapitalize: true) + name.objcName(shouldCapitalize: true)
            isEnum = true
        } else if let typeEnumType = Types.type(forDiscoveryType: info.type, format: info.format) {
            if info.enumValues == nil {
                propertyType = typeEnumType.rawValue
            }
        } else if let type = info.type {
            if type == "array" {
                var typeName: String = ""
                if let arrayType = info.items.xRef { // array of object already declared
                    typeName = "[\(serviceName + arrayType)]"
                } else if info.properties != nil || info.items.properties != nil { // array of a new type of object
                    var name = serviceName + resourceName.objcName(shouldCapitalize: true) + name.objcName(shouldCapitalize: true)
                    if name.characters.last == "s" {
                        name = String(name.characters.dropLast())
                    }
                    typeName = "[\(name)]"
                } else if info.items.type != nil && info.items.type != "object" { // array of primitive
                    let name = (Types.type(forDiscoveryType: info.items.type, format: info.items.format)?.rawValue)!
                    typeName = "[\(name)]"
                }
                propertyType = typeName
            } else if type == "object" && info.properties != nil {
                propertyType = serviceName + resourceName.objcName(shouldCapitalize: true) + name.objcName(shouldCapitalize: true)
            } else if info.additionalProperties != nil && info.additionalProperties.xRef != nil {
                propertyType = "[String: \(serviceName + info.additionalProperties.xRef)]"
            }
        } else if info.xRef != nil {
            propertyType = serviceName + info.xRef!
        }
        // 3) Transform Type
        let transformType = Types.transformType(forType: Types(rawValue: propertyType))?.rawValue
        // 4) Default Value
        var defaultValue = info.defaultValue
        if defaultValue != nil {
            if info.enumValues != nil {
                defaultValue = ".\(info.defaultValue!.objcName(shouldCapitalize: true))"
            } else if propertyType == Types.String.rawValue {
                defaultValue = "\"\(info.defaultValue!)\""
            }
        }
        
        // 5) Optionality
        var optionality = OptionalityOnType.ImplicitlyUnwrappedOptional
        if defaultValue != nil {
            optionality = OptionalityOnType.NonOptional
        }
        // 6) Required
        let required = (info.required != nil) ? true : false
        // 7) Description
        let desc = info.schemaDescription
        
        // 8) location in request (either query or path)
        let location = info.location
        
        // 9) put it all together
        return Property(nameFoundInJSONSchema: name, type: propertyType, optionality: optionality, transformType: transformType, defaultValue: defaultValue, required: required, description: desc, isEnum: isEnum, location: location)
    }
    
    func propertiesFromSchemaProperties(schemaProperties: [String: DiscoveryJSONSchema], resourceName: String, className: String) -> [Property] {
        var properties: [Property] = []
        for (propertyName, propertyInfo) in schemaProperties {
            let property = generateProperty(forName: propertyName, info: propertyInfo, resourceName: resourceName)
            if let override = OverrideFileManager.overrideModelClassProperty(name: propertyName, className: className) {
                if let typeOverride = override.type {
                    property.type = typeOverride
                }
                if let nameOverride = override.name {
                    property.name = nameOverride
                }
                if let defaultValueOverride = override.defaultValue {
                    property.defaultValue = defaultValueOverride
                }
            }
            properties.append(property)
        }
        return properties
    }
}
