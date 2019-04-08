//
//  DefaultResourceResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class DefaultConfigurationResolutionService: ConfigurationResolutionService {
    func url(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL? {
        let allBundles = Bundle.allBundles
        let currentBundle = Bundle(for: type(of: self))
        
        // Ensure that the current bundle is checked last.
        var nonCurrentBundles = allBundles.filter({ $0 != currentBundle })
        nonCurrentBundles.append(currentBundle)
        for bundle in nonCurrentBundles {
            if let resourceURL = bundle.url(forResource: resourceName, withExtension: resourceExtension) {
                return resourceURL
            }
        }
        return nil
    }
}
