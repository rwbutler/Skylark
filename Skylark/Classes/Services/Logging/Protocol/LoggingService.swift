//
//  LoggingService.swift
//  Skylark
//
//  Created by Ross Butler on 8/15/19.
//

import Foundation

protocol LoggingService {
    func log(_ message: String, level: LogLevel)
}
