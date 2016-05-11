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
        let globalQueryParams = SchemaToModelClassTransformer().propertiesFromSchemaProperties(discoveryDoc.parameters, resourceName: "")
        
        
        // 5) put it all together
        let serviceClass = ServiceClass(className: className, apiName: apiName, apiVersion: apiVersion, globalQueryParams: globalQueryParams)
        
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
            let name = methodName + resourceName.objcName(shouldCapitalize: true)
            // 2) Parameters
            let parameters = methodInfo.parameters != nil ? SchemaToModelClassTransformer().propertiesFromSchemaProperties(methodInfo.parameters, resourceName: resourceName) : []
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
            // 8) put it all together
            let method = APIMethod(name: name, requestMethod: requestMethod, parameters: parameters, jsonPostBodyType: requestType, jsonPostBodyVarName: requestTypeVarname, supportsMediaUpload: supportsMediaUploads, returnType: returnType, returnTypeVariableName: returnTypeVarname, endpoint: endpoint, serviceClass: serviceClass)
            methods.append(method)
        }
        return methods
    }
    
    func scopesEnum(fromSchema schema: [String: DiscoveryAuthScope]) -> ScopesEnum {
        // 1) values
        var values: [String] = []
        for (value, _) in schema {
            values.append(value)
        }
        
        return ScopesEnum(serviceName: self.serviceName, values: values)
    }
    
}
