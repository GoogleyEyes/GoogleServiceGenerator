//
//  OverrideFile.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/21/16.
//  Copyright © 2016 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import ObjectMapper

var APIOverrideFile: OverrideFile?

func loadOverrideFile(serviceName: String) {
    if let path = NSBundle.mainBundle().pathForResource("\(serviceName).override", ofType: "json") {
        if let fileData = NSData(contentsOfFile: path) {
            if let fileString = NSString(data: fileData, encoding: NSUTF8StringEncoding) {
                APIOverrideFile = Mapper<OverrideFile>().map(fileString)
            }
        }
    }
}

class OverrideFile: Mappable {
    var enums: [String: OverrideEnum]!
    var serviceClass: OverrideServiceClass!
    var modelClasses: [String: OverrideModelClass]!
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        enums <- map["enums"]
        serviceClass <- map["serviceClass"]
        modelClasses <- map["modelClasses"]
    }
}

class OverrideEnum: Mappable {
    var enumDict: [String: String]!
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        enumDict = map.JSONDictionary as? [String: String]
    }
    
    func overrideNameForInput(input: String) -> String? {
        return enumDict[input]
    }
    
    subscript(input: String) -> String? {
        return overrideNameForInput(input)
    }
}

class OverrideServiceClass: Mappable {
    var params: [String: OverrideProperty]!
    var methods: [String: OverrideServiceClassMethod]!
    var scopesEnum: [String: String]?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        params <- map["params"]
        methods <- map["methods"]
        scopesEnum <- map["scopesEnum"]
    }
}

class OverrideProperty: Mappable {
    var name: String?
    var defaultValue: String?
    var type: String?
    var hasDefaultValue: Bool = false
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        defaultValue <- map["defaultValue"]
        type <- map["type"]
        hasDefaultValue <- map["hasDefaultValue"]
    }
}

class OverrideServiceClassMethod: Mappable {
    var baseName: String?
    var paramNames: OverrideServiceClassMethodParamNames?
    var fullMethodName: String?
    var queryParams: [String: OverrideProperty]?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        baseName <- map["baseName"]
        paramNames <- map["paramNames"]
        fullMethodName <- map["fullMethodName"]
        queryParams <- map["queryParams"]
    }
}

class OverrideServiceClassMethodParamNames: Mappable {
    private var namesDict: [String: String]!
    
    subscript(index: Int) -> String? {
        let indexString = index.description // int to string
        return namesDict[indexString]
    }
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        namesDict = map.JSONDictionary as? [String: String]
    }
}

class OverrideModelClass: Mappable {
    var properties: [String: OverrideProperty]?
    var type: String?
    
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        properties <- map["properties"]
        type <- map["type"]
    }
}
