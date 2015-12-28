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
        let properties = schema.properties != nil ? propertiesFromSchemaProperties(schema.properties, resourceName: schemaName) : []
        // 3) superclass
        var superclass: String
        if schema.properties?["kind"] != nil {
            superclass = "GoogleObject"
        } else {
            superclass = "Mappable"
        }
        // 3) put it all together
        return ModelClass(className: className, superclass: superclass, properties: properties)
    }
    
    func modelListClassFromSchema(schemaName: String, schema: DiscoveryJSONSchema) -> ModelListClass {
        // 1) class name
        let className = serviceName + schemaName
        // 2) item type
        let itemType = serviceName + schema.properties["items"]!.items.xRef!
        // 3) properties
        var properties = propertiesFromSchemaProperties(schema.properties, resourceName: "")
        let itemProperties = weedOutItemsProperties(properties)
        for property in itemProperties {
            if property.type != "[Type]" {
                properties.removeAtIndex(properties.indexOf(property)!)
            }
        }
        // 4) items description
        let itemsDescription = schema.properties["items"]!.schemaDescription
        // 4) put it all together
        return ModelListClass(className: className, properties: properties, itemType: itemType, itemsPropertyDescription: itemsDescription)
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
            properties = propertiesFromSchemaProperties(schema.properties, resourceName: resourceName)
        } else if schema.items.type == "object" && schema.items.properties != nil {
            properties = propertiesFromSchemaProperties(schema.items.properties, resourceName: resourceName)
        }
        // 3) put it all together
        return ModelClass(className: className, superclass: Types.Mappable.rawValue, properties: properties)
    }
    
    func subModelClassForArrayValueTypeObjectFromSchema(schemaName: String, resourceName: String, schema: DiscoveryJSONSchema) -> ModelClass {
        // 1) class name
        let className = serviceName + resourceName.objcName(shouldCapitalize: true) + schemaName
        // 2) properties
        var properties: [Property] = []
        properties = propertiesFromSchemaProperties(schema.items.properties, resourceName: resourceName)
        // 3) put it all together
        return ModelClass(className: className, superclass: Types.Mappable.rawValue, properties: properties)
    }
    
    func propertiesFromSchemaProperties(schemaProperties: [String: DiscoveryJSONSchema], resourceName: String) -> [Property] {
        var properties: [Property] = []
        for (propertyName, propertyInfo) in schemaProperties {
            // 1) property type
            var propertyType = ""
            // 2) isEnum
            var isEnum: Bool = false
            if propertyInfo.enumValues != nil {
                propertyType = serviceName + resourceName.objcName(shouldCapitalize: true) + propertyName.objcName(shouldCapitalize: true)
                isEnum = true
            } else if let typeEnumType = Types.type(forDiscoveryType: propertyInfo.type, format: propertyInfo.format) {
                if propertyInfo.enumValues == nil {
                    propertyType = typeEnumType.rawValue
                }
            } else if let type = propertyInfo.type {
                if type == "array" {
                    var typeName: String = ""
                    if let arrayType = propertyInfo.items.xRef { // array of object already declared
                        typeName = "[\(serviceName + arrayType)]"
                    } else if propertyInfo.properties != nil || propertyInfo.items.properties != nil { // array of a new type of object
                        var name = serviceName + resourceName.objcName(shouldCapitalize: true) + propertyName.objcName(shouldCapitalize: true)
                        if name.characters.last == "s" {
                            name = String(name.characters.dropLast())
                        }
                        typeName = "[\(name)]"
                    } else if propertyInfo.items.type != nil && propertyInfo.items.type != "object" { // array of primitive
                        let name = (Types.type(forDiscoveryType: propertyInfo.items.type, format: propertyInfo.items.format)?.rawValue)!
                        typeName = "[\(name)]"
                    }
                    propertyType = typeName
                } else if type == "object" && propertyInfo.properties != nil {
                    propertyType = serviceName + resourceName.objcName(shouldCapitalize: true) + propertyName.objcName(shouldCapitalize: true)
                } else if propertyInfo.additionalProperties != nil && propertyInfo.additionalProperties.xRef != nil {
                    propertyType = "[String: \(serviceName + propertyInfo.additionalProperties.xRef)]"
                }
            } else if propertyInfo.xRef != nil {
                propertyType = serviceName + propertyInfo.xRef!
            }
            // 3) Transform Type
            let transformType = Types.transformType(forType: Types(rawValue: propertyType))?.rawValue
            // 4) Default Value
            var defaultValue = propertyInfo.defaultValue
            if defaultValue != nil {
                if propertyInfo.enumValues != nil {
                    defaultValue = ".\(propertyInfo.defaultValue!.objcName(shouldCapitalize: true))"
                } else if propertyType == Types.String.rawValue {
                    defaultValue = "\"\(propertyInfo.defaultValue!)\""
                }
            }
            
            // 5) Optionality
            var optionality = OptionalityOnType.ImplicitlyUnwrappedOptional
            if defaultValue != nil {
                optionality = OptionalityOnType.NonOptional
            }
            // 6) Required
            let required = (propertyInfo.required != nil) ? true : false
            // 7) Description
            let desc = propertyInfo.schemaDescription
            
            // 8) put it all together
            let property = Property(nameFoundInJSONSchema: propertyName, type: propertyType, optionality: optionality, transformType: transformType, defaultValue: defaultValue, required: required, description: desc, isEnum: isEnum)
            properties.append(property)
        }
        return properties
    }
}
