//
//  SystemTypes.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/5/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import Alamofire

enum Types: String {
    // System Types
    case String = "String"
    case URL = "URL"
    case Int = "Int"
    case UInt = "UInt"
    case Array = "Array"
    case any = "Any"
    case Bool = "Bool"
    case Double = "Double"
    case Float = "Float"
    case AnyObject = "AnyObject"
    case UInt64 = "UInt64"
    case Date = "Date"
    case Int64 = "Int64"
    case Data = "Data"
    
    // ObjectMapper
    case FromJSON = "FromJSON"
    case JSON = "JSON"
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
                                selfValue = Types.Data.rawValue
                            case "date":
                                selfValue = Types.Date.rawValue
                            case "date-time":
                                selfValue = Types.Date.rawValue
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
                    selfValue = Types.any.rawValue
                default: selfValue = ""
            }
        }
        
        
        return Types(rawValue: selfValue)
    }
}

extension Alamofire.HTTPMethod {
    var codeString: String {
        switch self {
        case .get: return "get"
        case .post: return "post"
        case .put: return "put"
        case .delete: return "delete"
        case .patch: return "patch"
        case .head: return "head"
        default: return ""
        }
    }
}
