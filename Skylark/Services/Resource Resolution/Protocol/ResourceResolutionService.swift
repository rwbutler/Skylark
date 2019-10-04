//
//  ResourceResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol ResourceResolutionService {
    
    /// Searches all bundles for the first matching resource checking the test bundle last.
    func url(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL?
    
    /// Convenience method for quickly retriving resources in the app's bundle.
    func urlInAppBundle(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL?
    
    /// Convenience method for quickly retrieving resources in the framework bundle.
    func urlInTestBundle(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL?
    
}
