//
//  ResourceResolutionService.swift
//  Skylark
//
//  Created by rossbutler on 3/3/19.
//

import Foundation

protocol ResourceResolutionService {
    func url(forResource resourceName: String?, withExtension resourceExtension: String?) -> URL?
}
