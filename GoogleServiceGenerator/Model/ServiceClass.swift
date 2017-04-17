//
//  ServiceClass.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/6/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import Stencil

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
        let globalQueryParamsStrings = globalQueryParams.map { (property) -> [String: String] in
            return ["declaration": "\(property)"]
        }
        let methods = apiMethods.map {
            $0.generateSourceFileString()
        }
        let context = Context(dictionary: [
            "globalQueryParams": globalQueryParamsStrings,
            "name": name,
            "setUpQueryParams": generateSetUpQueryParams(),
            "apiName": apiName,
            "apiVersion": apiVersion,
            "description": classDescription,
            "apiMethods": methods
            ])
        do {
            let template = try Template(named: "ServiceClass.stencil")
            let rendered = try template.render(context)
            return rendered
        } catch {
            print("Failed to render template \(error) for class \(name)")
            return ""
        }
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
    var requestMethod: Alamofire.HTTPMethod
    var jsonPostBodyType: String?
    var jsonPostBodyVarName: String?
    var supportsMediaUpload: Bool
    var methodId: String
    
    var methodDescription: String
    
    fileprivate var queryParams: [Property]
    
    init(name: String, requestMethod: Alamofire.HTTPMethod = .get, parameters: [Property], jsonPostBodyType: String? = nil, jsonPostBodyVarName: String? = nil, supportsMediaUpload: Bool = false, returnType: String?, returnTypeVariableName: String? = nil, endpoint: String, serviceClass: ServiceClass, description: String, methodId: String) {
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
            newReqPar.append(contentsOf: reqpar)
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
    
    var setUpQueryParams: String {
        var string = ""
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
        return string
    }
    
    var performRequestCall: String {
        var string = ""
        // 4) performRequest
        let endpointStr = endpoint.replacingOccurrences(of: "{", with: "\\(").replacingOccurrences(of: "}", with: ")")
        if requestMethod == .get {
            string += "fetcher.performRequest(serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams"
        } else if jsonPostBodyType != nil {
            string += "fetcher.performRequest(.\(requestMethod.codeString), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams, postBody: \(jsonPostBodyVarName!).toJSON()"
        } else {
            string += "fetcher.performRequest(.\(requestMethod.codeString), serviceName: apiNameInURL, apiVersion: apiVersionString, endpoint: \"\(endpointStr)\", queryParams: queryParams"
        }
        
        if supportsMediaUpload {
            string += ", uploadParameters: uploadParameters"
        }
        
        string += ")"
        return string
    }
    
    override func generateSourceFileString() -> String {
        let nonRequiredParamsStrings = nonRequiredParams.map { (property) -> [String: String] in
            return ["declaration": "\(property)"]
        }
        var serialization: String
        var valueVar: String
        if returnType == "Bool" {
            serialization = "completionHandler(.success(true))"
            valueVar = "_"
        } else {
            serialization = "completionHandler(.success(\(returnType)(json: value)))"
            valueVar = "let value"
        }
        let context = Context(dictionary: [
                "nonRequiredParams": nonRequiredParamsStrings,
                "name": generateMethodName(),
                "setUpQueryParams": setUpQueryParams,
                "performRequestCall": performRequestCall,
                "serialization": serialization,
                "valueVar": valueVar
            ])
        do {
            let template = try Template(named: "ServiceClassMethod.stencil")
            let rendered = try template.render(context)
            return rendered
        } catch {
            print("Failed to render template \(error) for method \(name)")
            return ""
        }
    }
    
    fileprivate func generateMethodName() -> String {
        
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
                    
                    var firstParamName: String? = nil
                    if let override = overrideParamNames?[0] {
                        if override != "_" {
                            firstParamName = override
                        } else {
                            firstParamName = nil
                        }
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
                    
                    if let overrideParamName = overrideParamNames?[requiredParams.index(of: param)!] {
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
        string += "completionHandler: @escaping (_ result: GoogleResult<\(returnType)>) -> ())"
        
        return string
    }
}
