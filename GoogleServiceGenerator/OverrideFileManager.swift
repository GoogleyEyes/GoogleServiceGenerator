//
//  OverrideFileManager.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/21/16.
//  Copyright © 2016 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class OverrideFileManager {
    class func overrideAPIBaseName(_ methodId: String) -> String? {
        if let overrideName = APIOverrideFile?.serviceClass?.methods?[apiMethodIdentifierWithoutServiceName(methodId)]?.baseName {
            return overrideName
        } else {
            return nil
        }
    }
    
    class func overrideAPIMethodFullName(_ methodId: String) -> String? {
        if let overrideName = APIOverrideFile?.serviceClass?.methods?[apiMethodIdentifierWithoutServiceName(methodId)]?.fullMethodName {
            return overrideName
        } else {
            return nil
        }
    }
    
    class func overrideAPIMethodParameterNames(_ methodId: String) -> OverrideServiceClassMethodParamNames? {
        if let overrideNames = APIOverrideFile?.serviceClass?.methods?[apiMethodIdentifierWithoutServiceName(methodId)]?.paramNames {
            return overrideNames
        } else {
            return nil
        }
    }
    
    class func overrideAPIEnumCaseNames(resourceName: String, propertyName: String, input: String) -> String? {
        let id: String
        if resourceName == "" {
            id = propertyName
        } else {
            id = [resourceName, propertyName].joined(separator: ".")
        }
        return APIOverrideFile?.enums?[id]?.overrideName(forInput: input)
    }
    
    class func overrideAPIGlobalQueryParam(_ propertyName: String) -> OverrideProperty? {
        return APIOverrideFile?.serviceClass?.params?[propertyName]
    }
    
    class func overrideAPIMethodQueryParam(_ methodId: String, propertyName: String) -> OverrideProperty? {
        let methodString = apiMethodIdentifierWithoutServiceName(methodId)
        return APIOverrideFile?.serviceClass?.methods?[methodString]?.queryParams?[propertyName]
    }
    
    class func overrideModelClass(className: String) -> OverrideModelClass? {
        return APIOverrideFile?.modelClasses?[className]
    }
    
    class func overrideModelClassProperty(name: String, className: String) -> OverrideProperty? {
        return overrideModelClass(className: className)?.properties?[name]
    }
    
    class func overrideScopesEnumCaseName(currentName name: String) -> String? {
        return APIOverrideFile?.serviceClass.scopesEnum?[name]
    }
    
    fileprivate class func apiMethodIdentifierWithoutServiceName(_ identifier: String) -> String {
        let id = identifier
        var parts = id.components(separatedBy: ".")
        parts.removeFirst()
        return parts.joined(separator: ".")
    }
}
