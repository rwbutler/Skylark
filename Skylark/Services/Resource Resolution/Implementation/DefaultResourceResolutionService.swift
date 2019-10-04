//
//  DefaultResourceResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class DefaultResourceResolutionService: ResourceResolutionService {
    
    /// Searches all bundles for the first matching resource checking the test bundle last.
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
    
    /// Convenience method for quickly retriving resources in the app's bundle.
    func urlInAppBundle(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL? {
        let testBundle = Bundle.main
        if let resourceURL = testBundle.url(forResource: resourceName, withExtension: resourceExtension) {
            return resourceURL
        }
        return nil
    }
    
    /// Convenience method for quickly retrieving resources in the framework bundle.
    func urlInTestBundle(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL? {
        let testBundle = Bundle(for: type(of: self))
        if let resourceURL = testBundle.url(forResource: resourceName, withExtension: resourceExtension) {
            return resourceURL
        }
        return nil
    }
    
}
