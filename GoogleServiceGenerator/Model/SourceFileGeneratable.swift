//
//  SourceFileGeneratable.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 9/6/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa

class SourceFileGeneratable: Equatable, Hashable {
    var name: String = "" // OVERRIDE
    
    func generateSourceFileString() -> String { // OVERRIDE
        return ""
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: SourceFileGeneratable, rhs: SourceFileGeneratable) -> Bool {
    return lhs.name == rhs.name
}