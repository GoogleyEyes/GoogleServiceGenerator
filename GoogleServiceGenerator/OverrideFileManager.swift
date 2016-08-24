//
//  OverrideFileManager.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/21/16.
//  Copyright © 2016 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class OverrideFileManager {
    class func overrideAPIBaseName(methodId: String) -> String? {
        if let overrideName = APIOverrideFile?.serviceClass.methods[apiMethodIdentifierWithoutServiceName(methodId)]?.baseName {
            return overrideName
        } else {
            return nil
        }
    }
    
    class func overrideAPIMethodFullName(methodId: String) -> String? {
        if let overrideName = APIOverrideFile?.serviceClass.methods[apiMethodIdentifierWithoutServiceName(methodId)]?.fullMethodName {
            return overrideName
        } else {
            return nil
        }
    }
    
    class func overrideAPIMethodParameterNames(methodId: String) -> OverrideServiceClassMethodParamNames? {
        if let overrideNames = APIOverrideFile?.serviceClass.methods[apiMethodIdentifierWithoutServiceName(methodId)]?.paramNames {
            return overrideNames
        } else {
            return nil
        }
    }
    
    class func overrideAPIEnumCaseNames(resourceName resourceName: String, propertyName: String, input: String) -> String? {
        let id: String
        if resourceName == "" {
            id = propertyName
        } else {
            id = [resourceName, propertyName].joinWithSeparator(".")
        }
        return APIOverrideFile?.enums[id]?.overrideNameForInput(input)
    }
    
    class func overrideAPIGlobalQueryParam(propertyName: String) -> OverrideProperty? {
        return APIOverrideFile?.serviceClass.params[propertyName]
    }
    
    class func overrideAPIMethodQueryParam(methodId: String, propertyName: String) -> OverrideProperty? {
        let methodString = apiMethodIdentifierWithoutServiceName(methodId)
        return APIOverrideFile?.serviceClass.methods[methodString]?.queryParams?[propertyName]
    }
    
    class func overrideModelClass(className className: String) -> OverrideModelClass? {
        return APIOverrideFile?.modelClasses?[className]
    }
    
    class func overrideModelClassProperty(name name: String, className: String) -> OverrideProperty? {
        return overrideModelClass(className: className)?.properties?[name]
    }
    
    class func overrideScopesEnumCaseName(currentName name: String) -> String? {
        return APIOverrideFile?.serviceClass.scopesEnum?[name]
    }
    
    private class func apiMethodIdentifierWithoutServiceName(identifier: String) -> String {
        let id = identifier
        var parts = id.componentsSeparatedByString(".")
        parts.removeFirst()
        return parts.joinWithSeparator(".")
    }
}
