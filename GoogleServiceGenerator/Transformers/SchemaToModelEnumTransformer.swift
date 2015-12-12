//
//  SchemaToModelEnumTransformer.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/17/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import GoogleAPIs

class SchemaToModelEnumTransformer {
    var serviceName: String = Generator.sharedInstance.serviceName
    
    func enumFromSchema(propertyName: String, resourceName: String, propertyInfo: DiscoveryJSONSchema) -> ModelEnum {
        // 1) Name
        let enumName = serviceName + resourceName.objcName(shouldCapitalize: true) + propertyName.objcName(shouldCapitalize: true)
        // 1) Type
        var enumType: String = ""
        if let typeEnumType = Types.type(forDiscoveryType: propertyInfo.type, format: propertyInfo.format) {
            if propertyInfo.enumValues != nil {
                enumType = typeEnumType.rawValue
            }
        }
        // 2) Cases
        var enumCases = propertyInfo.enumValues
        if enumType == "String" {
            enumCases = propertyInfo.enumValues.map { (rawValue) -> String in
                return "\"\(rawValue)\""
            }
        }
        // 3) CaseNames
        let caseNames = propertyInfo.enumValues.map { (rawValue) -> String in
            return rawValue.objcName(shouldCapitalize: true)
        }
        // 4) put it all together
        return ModelEnum(name: enumName, type: enumType, cases: enumCases, caseNames: caseNames)
    }
}
