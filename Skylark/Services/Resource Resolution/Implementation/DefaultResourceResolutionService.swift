//
//  DefaultResourceResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class DefaultResourceResolutionService: ResourceResolutionService {
    
    /// Checks the current bundle last.
    func url(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL? {
        let allBundles = Bundle.allBundles
        let currentBundle = Bundle(for: type(of: self))
        var bundles = allBundles.filter({ $0 != currentBundle })
        bundles.append(currentBundle)
        for bundle in bundles {
            if let resourceURL = bundle.url(forResource: resourceName, withExtension: resourceExtension) {
                return resourceURL
            }
        }
        return nil
    }
    
}
