//
//  Generator.swift
//  
//
//  Created by Matthew Wyskiel on 6/11/15.
//
//

import Cocoa
import GoogleAPIs

class Generator {
    static let sharedInstance = Generator()
    var folder: String = ""
    var serviceName: String = ""
    fileprivate init() {
        
    }
    
    func generate(serviceName name: String, version: String, destinationPath: String, completionHandler: @escaping (_ success: Bool, _ error: Error?) -> ()) {
        folder = destinationPath
        
        loadOverrideFile(name)
        
        Discovery().getDiscoveryDocument(forAPI: name, version: version, completionHandler: { result in
            if result.error != nil {
                completionHandler(false, result.error)
                return
            }
            if let discoveryDoc = result.value {
                self.serviceName = discoveryDoc.name.objcName(shouldCapitalize: true)
                // 1. Create model using Schemas
                var model = self.createModelUsingSchemas(fromDiscoveryDoc: discoveryDoc)
                // 2. Create main (fetcher) class
                let serviceClass = SchemaToServiceClassTransformer().serviceClass(fromDiscoveryDoc: discoveryDoc)
                // 3. add main class and other associated model to model dictionary
                var serviceModelItems: [SourceFileGeneratable] = [serviceClass]
                serviceModelItems.append(contentsOf: self.createExtraModelForGlobalQueryParams(discoveryDoc.parameters))
                serviceModelItems.append(contentsOf: self.createExtraModelForMethodsInDiscoveryDoc(discoveryDoc))
                serviceModelItems.append(SchemaToServiceClassTransformer().scopesEnum(fromSchema: discoveryDoc.auth.OAuthScopes))
                model[serviceClass.name] = serviceModelItems
                
                // 4. write files
                self.createFilesForGeneratedItems(model, completionHandler: { (success, error) -> () in
                    completionHandler(success, error)
                })
            }
        })
    }
    
    func createModelUsingSchemas(fromDiscoveryDoc discoveryDoc: DiscoveryRestDescription) -> [String: [SourceFileGeneratable]] {
        var model = [String: [SourceFileGeneratable]]()
        for (schemaName, schema) in discoveryDoc.schemas {
            var modelItems: [SourceFileGeneratable] = []
            if schema.properties?["items"] != nil {
                modelItems.append(SchemaToModelClassTransformer().modelListClassFromSchema(schemaName, schema: schema))
            } else {
                modelItems.append(SchemaToModelClassTransformer().modelClassFromSchema(schemaName, schema: schema))
            }
            if let properties = schema.properties {
                for (propertyName, propertyInfo) in properties {
                    if let type = propertyInfo.type {
                        if type == "object" && propertyInfo.properties != nil {
                            modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(propertyName.objcName(shouldCapitalize: true), resourceName: schemaName, schema: propertyInfo))
                            for (name, info) in propertyInfo.properties {
                                if let typetwo = info.type {
                                    if typetwo == "object" && info.properties != nil {
                                        modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(name.objcName(shouldCapitalize: true), resourceName: schemaName + propertyName.objcName(shouldCapitalize: true), schema: info))
                                    } else if typetwo == "array" && info.items.properties != nil {
                                        modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(name.objcName(shouldCapitalize: true), resourceName: schemaName + propertyName.objcName(shouldCapitalize: true), schema: info))
                                    }
                                } else if info.enumValues != nil {
                                    modelItems.append(SchemaToModelEnumTransformer().enumFromSchema(name, resourceName: schemaName + propertyName.objcName(shouldCapitalize: true), propertyInfo: info))
                                }
                            }
                        } else if type == "array" && propertyInfo.items.properties != nil {
                            modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(propertyName.objcName(shouldCapitalize: true), resourceName: schemaName, schema: propertyInfo))
                        } else if propertyInfo.enumValues != nil {
                            modelItems.append(SchemaToModelEnumTransformer().enumFromSchema(propertyName, resourceName: schemaName, propertyInfo: propertyInfo))
                        }
                    }
                }
            }
            
            model[serviceName + schemaName] = modelItems
        }
        return model
    }
    
    func createExtraModelForGlobalQueryParams(_ params: [String: DiscoveryJSONSchema]) -> [SourceFileGeneratable] {
        var modelItems: [SourceFileGeneratable] = []
        for (propertyName, propertyInfo) in params {
            if propertyInfo.type == "object" && propertyInfo.properties != nil {
                modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(propertyName, resourceName: "", schema: propertyInfo))
            } else if propertyInfo.enumValues != nil {
                modelItems.append(SchemaToModelEnumTransformer().enumFromSchema(propertyName, resourceName: "", propertyInfo: propertyInfo))
            }
        }
        return modelItems
    }
    
    func createExtraModelForMethodsInDiscoveryDoc(_ doc: DiscoveryRestDescription) -> [SourceFileGeneratable] {
        var modelItems: [SourceFileGeneratable] = []
        for (resourceName, resourceInfo) in doc.resources {
            for (_, methodInfo) in resourceInfo.methods {
                if methodInfo.parameters != nil {
                    for (propertyName, propertyInfo) in methodInfo.parameters {
                        if propertyInfo.type == "object" && propertyInfo.properties != nil {
                            modelItems.append(SchemaToModelClassTransformer().subModelClassFromSchema(propertyName, resourceName: resourceName, schema: propertyInfo))
                        } else if propertyInfo.enumValues != nil {
                            modelItems.append(SchemaToModelEnumTransformer().enumFromSchema(propertyName, resourceName: resourceName, propertyInfo: propertyInfo))
                        }
                    }
                }
                
            }
        }
        return modelItems
    }
    
    func createFilesForGeneratedItems(_ items: [String: [SourceFileGeneratable]], completionHandler: (_ success: Bool, _ error: Error?) -> ()) {
        for (itemName, itemContent) in items {
            let url = folder + "/\(itemName).swift"
            let content = completeString(itemContent, name: itemName)
            
            do {
                try content.write(toFile: url, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                completionHandler(false, error)
                return
            }
        }
        completionHandler (true, nil)
    }
    
    fileprivate func completeString(_ items: [SourceFileGeneratable], name: String) -> String {
        // 1. comments
        var string = "//"
        string.addNewLine()
        string += "//  \(name).swift"
        string.addNewLine()
        string += "//  GoogleAPISwiftClient"
        string.addNewLine()
        string += "//"
        string.addNewLine()
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        let dateString = formatter.string(from: Date())
        string += "//  Created by Matthew Wyskiel on \(dateString)."
        string.addNewLine()
        let comps = NSCalendar.current.dateComponents([.year], from: Date())
        string += "//  Copyright © \(comps.year) Matthew Wyskiel. All rights reserved."
        string.addNewLine()
        string += "//"
        string.addNewLine(); string.addNewLine()
        // 2. imports
        string += "import Foundation"
        string.addNewLine(); string.addNewLine()
        print("Items: \(items)")
        let itemSet = Set<SourceFileGeneratable>(items)
        print("Item Set: \(itemSet)")
        for item in itemSet {
            string += item.generateSourceFileString()
            string.addNewLine(); string.addNewLine();
        }
        return string
    }
    
}
