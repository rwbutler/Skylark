//
//  ResourceResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol ConfigurationResolutionService {
    func url(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL?
}
