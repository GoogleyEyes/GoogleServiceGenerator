//
//  SchemaToServiceClassTransformer.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/17/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import GoogleAPIs
import Alamofire

class SchemaToServiceClassTransformer {
    var serviceName: String = Generator.sharedInstance.serviceName
    
    func serviceClass(fromDiscoveryDoc discoveryDoc: DiscoveryRestDescription) -> ServiceClass {
        // 1) Class Name
        let className = discoveryDoc.name.objcName(shouldCapitalize: true)
        // 2) API Name
        let apiName = discoveryDoc.name
        // 3) API Version
        let apiVersion = discoveryDoc.version
        // 4) Global Query Parameters
        let listedParams = globalQueryParams("", schemaProperties: discoveryDoc.parameters)
        var globalParams: [Property] = []
        for param in listedParams {
            if param.name == "key" || param.name == "oauthToken" {
            } else {
                globalParams.append(param)
            }
        }
        
        // 4a) description
        let description = discoveryDoc.APIDescription
        
        // 5) put it all together
        let serviceClass = ServiceClass(className: className, apiName: apiName, apiVersion: apiVersion, globalQueryParams: globalParams, classDescription: description)
        
        // 6) API Methods
        var methods: [APIMethod] = []
        for (resourceName, resourceInfo) in discoveryDoc.resources {
            let resourceMethods = apiMethods(fromMethodsSchema: resourceInfo.methods, resourceName: resourceName, serviceClass: serviceClass)
            methods.appendContentsOf(resourceMethods)
        }
        serviceClass.apiMethods = methods
        
        return serviceClass
    }
    
    func apiMethods(fromMethodsSchema methodSchemas: [String: DiscoveryRestMethod], resourceName: String, serviceClass: ServiceClass) -> [APIMethod] {
        var methods: [APIMethod] = []
        for (methodName, methodInfo) in methodSchemas {
            // Craft each method
            // 1) Name
            let name: String
            if let overrideName = OverrideFileManager.overrideAPIBaseName(methodInfo.identifier) {
                name = overrideName
            } else {
                name = methodName + resourceName.objcName(shouldCapitalize: true)
            }
            // 2) Parameters
            let parameters = methodInfo.parameters != nil ? queryParamsForMethodId(methodInfo.identifier, resourceName: resourceName, schemaProperties: methodInfo.parameters) : []
            // 3) Return Type
            let returnType: String? = methodInfo.responseRef != nil ? serviceName + methodInfo.responseRef.objcName(shouldCapitalize: true) : nil
            // 4) Return type Variable Name
            let returnTypeVarname: String? = methodInfo.responseRef != nil ? methodInfo.responseRef.objcName(shouldCapitalize: false).makeCamelCaseLowerCase() : nil
            // 5) Endpoint
            let endpoint = methodInfo.path
            // 6) Request type and var name
            let requestType: String? = methodInfo.requestRef != nil ? serviceName + methodInfo.requestRef.objcName(shouldCapitalize: true) : nil
            let requestTypeVarname: String? = methodInfo.requestRef != nil ? methodInfo.requestRef.objcName(shouldCapitalize: false).makeCamelCaseLowerCase(): nil
            let requestMethod = Alamofire.Method(rawValue: methodInfo.httpMethod)!
            // 7) supports media uploads
            let supportsMediaUploads = methodInfo.supportsMediaUpload != nil ? methodInfo.supportsMediaUpload : false
            // 8) description
            let description = methodInfo.methodDescription
            // 9) put it all together
            let method = APIMethod(name: name, requestMethod: requestMethod, parameters: parameters, jsonPostBodyType: requestType, jsonPostBodyVarName: requestTypeVarname, supportsMediaUpload: supportsMediaUploads, returnType: returnType, returnTypeVariableName: returnTypeVarname, endpoint: endpoint, serviceClass: serviceClass, description: description, methodId: methodInfo.identifier)
            methods.append(method)
        }
        return methods
    }
    
    func scopesEnum(fromSchema schema: [String: DiscoveryAuthScope]) -> ScopesEnum {
        // 1) values
        var values: [String] = []
        var descriptions: [String] = []
        for (value, obj) in schema {
            values.append(value)
            descriptions.append(obj.scopeDescription)
        }
        
        return ScopesEnum(serviceName: self.serviceName, values: values, scopeDescriptions: descriptions)
    }
    
    func queryParamsForMethodId(id: String, resourceName: String, schemaProperties: [String: DiscoveryJSONSchema]) -> [Property] {
        var properties: [Property] = []
        for (propertyName, propertyInfo) in schemaProperties {
            let property = SchemaToModelClassTransformer().generateProperty(forName: propertyName, info: propertyInfo, resourceName: resourceName)
            if let override = OverrideFileManager.overrideAPIMethodQueryParam(id, propertyName: propertyName) {
                if let typeOverride = override.type {
                    property.type = typeOverride
                }
                if let nameOverride = override.name {
                    property.name = nameOverride
                }
                if override.hasDefaultValue {
                    property.hasDefaultValue = true
                }
                if let defaultValueOverride = override.defaultValue {
                    property.defaultValue = defaultValueOverride
                }
            }
            properties.append(property)
        }
        return properties
    }
    
    func globalQueryParams(resourceName: String, schemaProperties: [String: DiscoveryJSONSchema]) -> [Property] {
        var properties: [Property] = []
        for (propertyName, propertyInfo) in schemaProperties {
            let property = SchemaToModelClassTransformer().generateProperty(forName: propertyName, info: propertyInfo, resourceName: resourceName)
            if let override = OverrideFileManager.overrideAPIGlobalQueryParam(propertyName) {
                if let typeOverride = override.type {
                    property.type = typeOverride
                }
                if let nameOverride = override.name {
                    property.name = nameOverride
                }
                if override.hasDefaultValue {
                    property.hasDefaultValue = true
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
