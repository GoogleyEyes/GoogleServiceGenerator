//
//  ServiceClass.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/6/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class ServiceClass: SourceFileGeneratable, CustomStringConvertible {
    var apiName: String
    var apiVersion: String
    var globalQueryParams: [Property]
    var otherQueryParams: [Property] = []
    var apiMethods: [APIMethod] = []
    var classDescription: String
    
    init(className: String, apiName: String, apiVersion: String, globalQueryParams: [Property], classDescription: String) {
        self.apiName = apiName
        self.apiVersion = apiVersion
        self.globalQueryParams = []
        for param in globalQueryParams {
            if param.name != "key" || param.name != "oauthToken" {
                self.globalQueryParams.append(param)
            }
        }
        self.classDescription = classDescription
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return ""
    }
    
    override func generateSourceFileString() -> String {
        // 1) class declaration
        var string = classDescription.documentationString()
        string.addNewLine()
        string += "public class \(name): GoogleService {"
        string.addNewLine(); string.addTab()
        
        // 2) GoogleService conformance
        string += generateGoogleServiceConformance()
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 3) global query params
        for queryParam in globalQueryParams {
            string += "\(queryParam)"
            string.addNewLine(); string.addTab()
        }
        string.addNewLine(); string.addTab()
        
        // 4) API methods
        for method in apiMethods {
            string += method.generateSourceFileString()
            string.addNewLine(); string.addNewLine(); string.addTab()
        }
        
        // 5) setUpQueryParams
        string += generateSetUpQueryParams()
        string.addNewLine()
        string += "}"
        return string
    }
    
    func generateGoogleServiceConformance() -> String {
        // 1) apiNameInURL
        var string = "var apiNameInURL: String = \"\(apiName)\""
        string.addNewLine(); string.addTab()
        
        // 2) apiVersionString
        string += "var apiVersionString: String = \"\(apiVersion)\""
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 5) fetcher
        string += "public let fetcher: GoogleServiceFetcher = GoogleServiceFetcher()"
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        string += "public required init() {"
        string.addNewLine(); string.addNewLine(); string.addTab()
        string += "}"
        
        
        return string
    }
    
    func generateSetUpQueryParams() -> String {
        var string = "func setUpQueryParams() -> [String: String] {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "var queryParams = [String: String]()"
        string.addNewLine(); string.addTab(); string.addTab()
        for param in globalQueryParams {
            if param.defaultValue == nil {
                string += "if let \(param.name) = \(param.name) {"
                string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
            }
            if param.type != Types.String.rawValue && !param.isEnum {
                string += "queryParams.updateValue(\(param.name).toJSONString(), forKey: \"\(param.jsonName)\")"
            } else if param.isEnum {
                string += "queryParams.updateValue(\(param.name).rawValue, forKey: \"\(param.jsonName)\")"
            } else {
                string += "queryParams.updateValue(\(param.name), forKey: \"\(param.jsonName)\")"
            }
            if param.defaultValue == nil {
                string.addNewLine(); string.addTab(); string.addTab()
                string += "}"
            }
            string.addNewLine(); string.addTab(); string.addTab()
        }
        string += "return queryParams"
        string.addNewLine(); string.addTab()
        string += "}"
        return string
    }
}

import Alamofire

class APIMethod: SourceFileGeneratable, CustomStringConvertible {
    var requiredParams: [Property]
    var nonRequiredParams: [Property]
    var parameters: [Property]
    var returnType: String // Schema name preceded by Service Name
    var returnTypeVariableName: String // (schema name).objcName(shouldCapitalize: false)
    var endpoint: String
    weak var serviceClass: ServiceClass!
    var requestMethod: Alamofire.Method
    var jsonPostBodyType: String?
    var jsonPostBodyVarName: String?
    var supportsMediaUpload: Bool
    var methodId: String
    
    var methodDescription: String
    
    private var queryParams: [Property]
    
    init(name: String, requestMethod: Alamofire.Method = .GET, parameters: [Property], jsonPostBodyType: String? = nil, jsonPostBodyVarName: String? = nil, supportsMediaUpload: Bool = false, returnType: String?, returnTypeVariableName: String? = nil, endpoint: String, serviceClass: ServiceClass, description: String, methodId: String) {
        self.parameters = parameters
        self.requiredParams = []
        self.serviceClass = serviceClass
        self.nonRequiredParams = []
        self.queryParams = []
        for param in self.parameters {
            if param.required {
                self.requiredParams.append(param)
            } else {
                if !self.serviceClass.otherQueryParams.contains(param) {
                    self.nonRequiredParams.append(param)
                    self.serviceClass.otherQueryParams.append(param)
                }
            }
            if param.location == "query" {
                self.queryParams.append(param)
            }
        }
        self.returnType = returnType != nil ? returnType! : Types.Bool.rawValue
        self.returnTypeVariableName = returnTypeVariableName != nil ? returnTypeVariableName! : "success"
        self.endpoint = endpoint
        self.requestMethod = requestMethod
        self.jsonPostBodyType = jsonPostBodyType
        self.jsonPostBodyVarName = jsonPostBodyVarName
        if jsonPostBodyType != nil {
            let reqpar = self.requiredParams
            var newReqPar = [Property(nameFoundInJSONSchema: jsonPostBodyVarName!, type: jsonPostBodyType!, optionality: .NonOptional, required: true, description: "Post Body")]
            newReqPar.appendContentsOf(reqpar)
            self.requiredParams = newReqPar
        }
        self.supportsMediaUpload = supportsMediaUpload
        
        self.methodDescription = description
        self.methodId = methodId
        
        super.init()
        self.name = name
    }
    
    var description: String {
        return generateMethodName()
    }
    
    override func generateSourceFileString() -> String {
        // 1) Non-required query param declarations
        var string = ""
        for queryParam in nonRequiredParams {
            string += queryParam.generateSourceFileString()
            string.addNewLine(); string.addTab()
            if queryParam == nonRequiredParams.last! {
                string.addNewLine(); string.addTab()
            }
        }
        
        // 2) Method name
        string += methodDescription.documentationString()
        string.addNewLine(); string.addTab()
        string += generateMethodName() + " {"
        string.addNewLine()
        string.addTab(); string.addTab()
        
        // 3) setUpQueryParams
        if queryParams.count > 0 {
            string += "var queryParams = setUpQueryParams()"
        } else {
            string += "let queryParams = setUpQueryParams()"
        }
        
        string.addNewLine()
        string.addTab(); string.addTab()
        for queryParam in queryParams {
            if !(queryParam.required) {
                if !(queryParam.hasDefaultValue) {
                    string += "if let \(queryParam.name) = \(queryParam.name) {"
                    string.addNewLine();
                    string.addTab(); string.addTab(); string.addTab()
                }
            }
            if queryParam.type != Types.String.rawValue && !queryParam.isEnum {
                string += "queryParams.updateValue(\(queryParam.name).toJSONString(), forKey: \"\(queryParam.name)\")"
            } else if queryParam.isEnum {
                string += "queryParams.updateValue(\(queryParam.name).rawValue, forKey: \"\(queryParam.name)\")"
            } else {
                string += "queryParams.updateValue(\(queryParam.name), forKey: \"\(queryParam.name)\")"
            }
            
            if !(queryParam.required) {
                if !(queryParam.hasDefaultValue) {
                    string.addNewLine(); string.addTab(); string.addTab()
                    string += "}"
                }
            }
            
            string.addNewLine(); string.addTab(); string.addTab()
        }
        
        // 4) performRequest
        let endpointStr = endpoint.stringByReplacingOccurrencesOfString("{", withString: "\\(").stringByReplacingOccurrencesOfString("}", withString: ")")
        if requestMethod == .GET {
            string += "fetcher.performRequest(serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams"
        } else if jsonPostBodyType != nil {
            string += "fetcher.performRequest(.\(requestMethod.rawValue), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams, postBody: Mapper<\(jsonPostBodyType!)>().toJSON(\(jsonPostBodyVarName!))"
        } else {
            string += "fetcher.performRequest(.\(requestMethod.rawValue), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams"
        }
        
        if supportsMediaUpload {
            string += ", uploadParameters: uploadParameters"
        }
        
        string += ") { (JSON, error) -> () in"
        
        string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
        if returnType != Types.Bool.rawValue {
            // 4.1) completionHandler
            string += "if error != nil {"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab(); string.addTab()
            string += "completionHandler(\(returnTypeVariableName): nil, error: error)"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
            string += "} else if JSON != nil {"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab(); string.addTab()
            string += "let \(returnTypeVariableName) = Mapper<\(returnType)>().map(JSON)"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab(); string.addTab()
            string += "completionHandler(\(returnTypeVariableName): \(returnTypeVariableName), error: nil)"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
            string += "}"
            string.addNewLine(); string.addTab(); string.addTab()
            string += "}"
            string.addNewLine(); string.addTab()
        } else {
            // 4.1) completionHandler
            string += "if error != nil {"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab(); string.addTab()
            string += "completionHandler(success: false, error: error)"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
            string += "} else {"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab(); string.addTab()
            string += "completionHandler(success: true, error: nil)"
            string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
            string += "}"
            string.addNewLine(); string.addTab(); string.addTab()
            string += "}"
            string.addNewLine(); string.addTab()
        }
        
        
        // 5) closing bracket
        string += "}"
        return string
    }
    
    private func generateMethodName() -> String {
        
        // 1) initial method name
        var string = "public func "
        
        if let overridenMethodName = OverrideFileManager.overrideAPIMethodFullName(methodId) {
            return string + overridenMethodName
        }
        
        string += "\(name)("
        
        let overrideParamNames = OverrideFileManager.overrideAPIMethodParameterNames(methodId)
        
        // 2) required parameters
        if !requiredParams.isEmpty {
            for param in requiredParams {
                if param == requiredParams.first! {
                    
                    let firstParamName: String?
                    if let override = overrideParamNames?[0] {
                        if override != "_" {
                            firstParamName = override
                        } else {
                            firstParamName = nil
                        }
                    } else {
                        firstParamName = param.name
                    }
                    if firstParamName != nil {
                        string += "\(firstParamName!) "
                    }
                        
                    string += "\(param.name): \(param.type)\(param.optionality.rawValue)"
                    if param.defaultValue != nil {
                        string += " = \(param.defaultValue)"
                    }
                    string += ", "
                } else {
                    
                    if let overrideParamName = overrideParamNames?[requiredParams.indexOf(param)!] {
                        string += "\(overrideParamName) "
                    }
                    
                    string += "\(param.name): \(param.type)\(param.optionality.rawValue)"
                    if param.defaultValue != nil {
                        string += " = \(param.defaultValue)"
                    }
                    string += ", "
                }
            }
        }
        
        // 3) supports media uploads
        if supportsMediaUpload {
            string += "uploadParameters: UploadParameters"
            string += ", "
        }
        
        // 4) completion handler
        string += "completionHandler: (\(returnTypeVariableName): \(returnType)?, error: NSError?) -> ())"
        
        return string
    }
}