//
//  Property.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 6/26/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class Property: SourceFileGeneratable, CustomStringConvertible {
    var jsonName: String // used for ObjectMapper
    var type: String
    var optionality: OptionalityOnType
    var transformType: String?
    var defaultValue: String? {
        didSet {
            if defaultValue != nil {
                hasDefaultValue = true
            } else {
                hasDefaultValue = false
            }
        }
    }
    var required: Bool
    var docDescription: String?
    var isEnum: Bool
    var location: String?
    var hasDefaultValue: Bool
    var arrayItemType: String?
    var dictionaryItemType: String?
    var isModelType: Bool
    
    init(nameFoundInJSONSchema jsonName: String, type: String, optionality: OptionalityOnType, transformType: String? = nil, defaultValue: String? = nil, required: Bool = false, description: String?, isEnum: Bool = false, location: String? = nil, arrayItemType: String? = nil, dictionaryItemType: String? = nil, isModelType: Bool = false) {
        self.jsonName = jsonName
        self.type = type
        self.optionality = optionality
        self.transformType = transformType
        self.defaultValue = defaultValue
        if defaultValue == nil {
            hasDefaultValue = false
        } else {
            hasDefaultValue = true
            self.optionality = .NonOptional
        }
        self.required = required
        if required {
            self.optionality = .NonOptional
        }
        docDescription = description
        self.isEnum = isEnum
        self.location = location
        self.arrayItemType = arrayItemType
        self.dictionaryItemType = dictionaryItemType
        self.isModelType = isModelType
        
        super.init()
        self.name = jsonName.objcName(shouldCapitalize: false) // edit jsonName to fit source file character restrictions

    }
    
    var description: String {
        return generateSourceFileString()
    }
    
    override func generateSourceFileString() -> String {
        var string = ""
        if let desc = docDescription {
            string += desc.documentationString()
            string.addNewLine(); string.addTab()
            string += "public var \(name): \(type)\(optionality.rawValue)"
        } else {
            string += "public var \(name): \(type)\(optionality.rawValue)"
        }
        
        if defaultValue != nil {
            string += " = \(defaultValue!)"
        }
        
        if jsonName != name {
            string += "// \(jsonName)"
            if required {
                string += " - REQUIRED"
            }
        } else if required {
            string += " // REQUIRED"
        }
        
        return string
    }
    
    func namesAreNotEqual(_ one: Property, _ two: Property) -> Bool {
        return one.name != two.name
    }
    
    var toJSONMethodLine: String {
        var string = "dict[\"\(jsonName)\"] = "
        if let systemType = Types(rawValue: type) {
            switch systemType {
            case .any, .AnyObject, .Bool, .Double, .Float, .Int, .Int64, .String, .UInt, .UInt64:
                string += name
            case .Data:
                string += "\(name).base64EncodedString()"
            case .Date:
                string += "\(name).toJSONString()"
            case .URL:
                string += "\(name).absoluteString"
            default:
                break
            }
        } else if dictionaryItemType != nil {
            string += "Dictionary(\(name).map {/n/t\t($0.key, $0.value.toJSON())\n\t})"
        } else if arrayItemType != nil {
            string += name
        } else {
            string += "\(name).toJSON()"
        }
        return string
    }
    
    fileprivate var jsonTypeAccessor: String? {
        return jsonAccessor(forType: type, optionality: optionality)
    }
    
    var initWithJSONMethodLine: String {
        var string = "\(name) = "
        if let systemType = Types(rawValue: type) {
            switch systemType {
            case .any, .AnyObject, .Bool, .Data, .Date, .Double, .Float, .Int, .Int64, .String, .UInt, .UInt64, .URL:
                string += "json[\"\(jsonName)\"].\(jsonTypeAccessor!)"
            default:
                break
            }
        } else if arrayItemType != nil {
            let accessor = jsonAccessor(forType: arrayItemType!, optionality: optionality)
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                if accessor != nil {
                    string += "json[\"\(jsonName)\"].toJSONSubtypeArray()"
                } else {
                    string += "json[\"\(jsonName)\"].toModelArray()"
                }
                
            case .NonOptional:
                if accessor != nil {
                    string += "json[\"\(jsonName)\"].toJSONSubtypeArrayValue()"
                } else {
                    string += "json[\"\(jsonName)\"].toModelArrayValue()"
                }
            }
        } else if dictionaryItemType != nil {
            let accessor = jsonAccessor(forType: dictionaryItemType!, optionality: optionality)
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                if accessor != nil {
                    string += "json[\"\(jsonName)\"].toJSONSubtypeDictionary(\(dictionaryItemType!).self)"
                } else {
                    string += "json[\"\(jsonName)\"].toModelDictionary(\(dictionaryItemType!).self)"
                }
                
            case .NonOptional:
                if accessor != nil {
                    string += "json[\"\(jsonName)\"].toJSONSubtypeDictionaryValue(\(dictionaryItemType!).self)"
                } else {
                    string += "Dictionary(json[\"\(jsonName)\"].toModelDictionaryValue(\(dictionaryItemType!).self)"
                }
            }
        } else if isModelType {
            string += "\(type)(json: json[\"\(jsonName)\"])"
        }
        return string
    }
}

fileprivate func jsonAccessor(forType type: String, optionality: OptionalityOnType) -> String? {
    if let systemType = Types(rawValue: type) {
        switch systemType {
        case .Bool:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "bool"
            case .NonOptional:
                return "boolValue"
            }
        case .Data:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "base64"
            case .NonOptional:
                return "base64Value"
            }
        case .Date:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "rfc3339"
            case .NonOptional:
                return "rfc3339Value"
            }
        case .Double:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "double"
            case .NonOptional:
                return "doubleValue"
            }
        case .Float:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "float"
            case .NonOptional:
                return "floatValue"
            }
        case .Int:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "integer"
            case .NonOptional:
                return "integerValue"
            }
        case .Int64:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "int64"
            case .NonOptional:
                return "int64Value"
            }
        case .String:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "string"
            case .NonOptional:
                return "stringValue"
            }
        case .UInt:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "uInt"
            case .NonOptional:
                return "uIntValue"
            }
        case .UInt64:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "uInt64"
            case .NonOptional:
                return "uInt64Value"
            }
        case .URL:
            switch optionality {
            case .ImplicitlyUnwrappedOptional, .Optional:
                return "url"
            case .NonOptional:
                return "urlValue"
            }
        case .any:
            return "toNative()"
        default:
            return nil
        }
    }
    return nil
}

func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name && lhs.type == rhs.type && lhs.optionality == rhs.optionality && lhs.defaultValue == rhs.defaultValue
}

enum OptionalityOnType: String {
    case Optional = "?"
    case NonOptional = ""
    case ImplicitlyUnwrappedOptional = "!"
}
