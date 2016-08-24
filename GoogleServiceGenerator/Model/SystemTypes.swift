//
//  SystemTypes.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/5/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

enum Types: String {
    // System Types
    case String = "String"
    case NSURL = "NSURL"
    case Int = "Int"
    case UInt = "UInt"
    case Array = "Array"
    case Any = "Any"
    case Bool = "Bool"
    case Double = "Double"
    case Float = "Float"
    case AnyObject = "AnyObject"
    case UInt64 = "UInt64"
    case NSDate = "NSDate"
    case Int64 = "Int64"
    case NSData = "NSData"
    
    // ObjectMapper
    case Mappable = "Mappable"
    case Map = "Map"
    case URLTransform = "URLTransform"
    case DateTransform = "DateTransform"
    case ISO8601DateTransrom = "ISO8601DateTransform"
    case RFC3339Transform = "RFC3339Transform"
    case Base64Transform = "Base64Transform"
}

extension Types {
    static func type(forDiscoveryType discoveryType: Swift.String?, format: Swift.String? = nil) -> Types? {
        var selfValue: Swift.String = ""
        if let type = discoveryType {
            switch type {
                case "boolean":
                    selfValue = Types.Bool.rawValue
                case "integer":
                    if let intFormat = format {
                        switch intFormat {
                            case "int32":
                                selfValue = Types.Int.rawValue
                            case "uint32":
                                selfValue = Types.UInt.rawValue
                            default:
                                selfValue = ""
                        }
                    }
                case "number":
                    if let numFormat = format {
                        switch numFormat {
                            case "double":
                                selfValue = Types.Double.rawValue
                            case "float":
                                selfValue = Types.Float.rawValue
                            default:
                                selfValue = ""
                        }
                    }
                case "string":
                    if let strFormat = format {
                        switch strFormat {
                            case "byte":
                                selfValue = Types.NSData.rawValue
                            case "date":
                                selfValue = Types.NSDate.rawValue
                            case "date-time":
                                selfValue = Types.NSDate.rawValue
                            case "int64":
                                selfValue = Types.Int64.rawValue
                            case "uint64":
                                selfValue = Types.UInt64.rawValue
                            default: selfValue = ""
                        }
                    } else {
                        selfValue = Types.String.rawValue
                    }
                case "any":
                    selfValue = Types.Any.rawValue
                default: selfValue = ""
            }
        }
        
        
        return Types(rawValue: selfValue)
    }
    
    static func transformType(forType type: Types?) -> Types? {
        let returnType: Types?
        if let existingType = type {
            switch existingType {
            case .NSURL:
                returnType = .URLTransform
            case .NSDate:
                returnType = .RFC3339Transform
            case .NSData:
                returnType = .Base64Transform
            default:
                returnType = nil
            }
        } else {
            returnType = nil
        }
        return returnType
    }
}
