//
//  DictionaryAdditions.swift
//  Skylark
//
//  Created by Ross Butler on 10/1/18.
//

import Foundation

extension Dictionary {
    
    init?(_ elements: [(key: Key?, value: Value?)]?) {
        guard let elements = elements else {
            return nil
        }
        self.init(elements)
    }
    
    init(_ elements: [Element]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
    
    init(_ elements: [(key: Key?, value: Value?)]) {
        self.init()
        for (key, value) in elements {
            if let key = key,
                let value = value {
                updateValue(value, forKey: key)
            }
        }
    }
    
    init(_ elements: [(key: Key, value: Value)?]) {
        self.init()
        for (key, value) in elements.compactMap({ $0 }) {
            updateValue(value, forKey: key)
        }
    }
    
    init(_ element: (key: Key, value: Value)?) {
        self.init()
        if let key = element?.key, let value = element?.value {
            updateValue(value, forKey: key)
        }
    }
    
    mutating func merge(dict: [Key: Value]) {
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
