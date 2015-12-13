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
    
    init(className: String, apiName: String, apiVersion: String, globalQueryParams: [Property]) {
        self.apiName = apiName
        self.apiVersion = apiVersion
        self.globalQueryParams = []
        for param in globalQueryParams {
            if param.name != "key" || param.name != "oauthToken" {
                self.globalQueryParams.append(param)
            }
        }
        
        super.init()
        self.name = className
    }
    
    var description: String {
        return ""
    }
    
    override func generateSourceFileString() -> String {
        // 1) class declaration
        var string = "public class \(name): GoogleService {"
        string.addNewLine(); string.addTab()
        
        // 2) GoogleService conformance
        string += generateGoogleServiceConformance()
        string.addNewLine(); string.addNewLine(); string.addTab()
        
        // 3) global query params
        for param in globalQueryParams {
            string += "\(param)"
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
        
        // 3) accessToken
        string += "/// OAuth 2.0 token for the current user."
        string.addNewLine(); string.addTab()
        string += "public var accessToken: String? {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "didSet {"
        string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
        string += "GoogleServiceFetcher.sharedInstance.accessToken = accessToken"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "}"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addTab()
        
        // 4) apiKey
        string += "/// API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token."
        string.addNewLine(); string.addTab()
        string += "public var apiKey: String? {"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "didSet {"
        string.addNewLine(); string.addTab(); string.addTab(); string.addTab()
        string += "GoogleServiceFetcher.sharedInstance.apiKey = apiKey"
        string.addNewLine(); string.addTab(); string.addTab()
        string += "}"
        string.addNewLine(); string.addTab()
        string += "}"
        string.addNewLine(); string.addTab()
        
        // 5) sharedInstance and private init()
        string += "public static let sharedInstance = \(name)()"
        string.addNewLine(); string.addTab()
        string += "private init() {"
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
            }
            string.addNewLine(); string.addTab(); string.addTab()
            if param.defaultValue == nil {
                string.addTab()
            }
            if param.type != Types.String.rawValue && !param.isEnum {
                string += "queryParams.updateValue(\(param.name).toJSONString(), forKey: \"\(param.name)\")"
            } else if param.isEnum {
                string += "queryParams.updateValue(\(param.name).rawValue, forKey: \"\(param.name)\")"
            } else {
                string += "queryParams.updateValue(\(param.name), forKey: \"\(param.name)\")"
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
    
    init(name: String, requestMethod: Alamofire.Method = .GET, parameters: [Property], jsonPostBodyType: String? = nil, jsonPostBodyVarName: String? = nil, returnType: String?, returnTypeVariableName: String? = nil, endpoint: String, serviceClass: ServiceClass) {
        self.parameters = parameters
        self.requiredParams = []
        self.serviceClass = serviceClass
        self.nonRequiredParams = []
        for param in self.parameters {
            if param.required {
                self.requiredParams.append(param)
            } else {
                if !self.serviceClass.otherQueryParams.contains(param) {
                    self.nonRequiredParams.append(param)
                    self.serviceClass.otherQueryParams.append(param)
                }
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
        string += generateMethodName() + " {"
        string.addNewLine()
        string.addTab(); string.addTab()
        
        // 3) setUpQueryParams
        if !nonRequiredParams.isEmpty {
            string += "var queryParams = setUpQueryParams()"
        } else {
            string += "let queryParams = setUpQueryParams()"
        }
        
        string.addNewLine()
        string.addTab(); string.addTab()
        for queryParam in nonRequiredParams {
            if queryParam.defaultValue == nil {
                string += "if let \(queryParam.name) = \(queryParam.name) {"
            }
            string.addNewLine(); string.addTab(); string.addTab()
            if queryParam.defaultValue == nil {
                string.addTab()
            }
            if queryParam.type != Types.String.rawValue && !queryParam.isEnum {
                string += "queryParams.updateValue(\(queryParam.name).toJSONString(), forKey: \"\(queryParam.name)\")"
            } else if queryParam.isEnum {
                string += "queryParams.updateValue(\(queryParam.name).rawValue, forKey: \"\(queryParam.name)\")"
            } else {
                string += "queryParams.updateValue(\(queryParam.name), forKey: \"\(queryParam.name)\")"
            }
            if queryParam.defaultValue == nil {
                string.addNewLine(); string.addTab(); string.addTab()
                string += "}"
            }
            string.addNewLine(); string.addTab(); string.addTab()
        }
        
        // 4) performRequest
        let endpointStr = endpoint.stringByReplacingOccurrencesOfString("{", withString: "\\(").stringByReplacingOccurrencesOfString("}", withString: ")")
        if requestMethod == .GET {
            string += "GoogleServiceFetcher.sharedInstance.performRequest(serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams) { (JSON, error) -> () in"
        } else if jsonPostBodyType != nil {
            string += "GoogleServiceFetcher.sharedInstance.performRequest(.\(requestMethod.rawValue), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams, postBody: Mapper<\(jsonPostBodyType!)>().toJSON(\(jsonPostBodyVarName!))) { (JSON, error) -> () in"
        } else {
            string += "GoogleServiceFetcher.sharedInstance.performRequest(.\(requestMethod.rawValue), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams) { (JSON, error) -> () in"
        }
        
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
        var string = "public func \(name)("
        
        // 2) required parameters
        if !requiredParams.isEmpty {
            for param in requiredParams {
                if param == requiredParams.first! {
                    string += "\(param.name) \(param.name): \(param.type)\(param.optionality.rawValue)"
                    if param.defaultValue != nil {
                        string += " = \(param.defaultValue)"
                    }
                    string += ", "
                } else {
                    string += "\(param.name): \(param.type)\(param.optionality.rawValue)"
                    if param.defaultValue != nil {
                        string += " = \(param.defaultValue)"
                    }
                    string += ", "
                }
            }
        }
        
        // 3) completion handler
        string += "completionHandler: (\(returnTypeVariableName): \(returnType)?, error: ErrorType?) -> ())"
        
        return string
    }
}