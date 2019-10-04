//
//  DefaultLoggingService.swift
//  Skylark
//
//  Created by Ross Butler on 8/15/19.
//

import Foundation
import os

class DefaultLoggingService: LoggingService {
    
    @available(iOS 10.0, *)
    private static let log = OSLog(subsystem: subsystem, category: "skylark")
    private static let subsystem = "com.rwbutler.skylark"
    
    func log(_ message: String, level: LogLevel) {
        if #available(iOS 10, *) {
            let logLevel = unifiedLogLevel(level)
            os_log("%@", log: type(of: self).log, type: logLevel, message)
        } else {
             NSLog(String(describing: message))
        }
    }
    
    @available(iOS 10.0, *)
    private func unifiedLogLevel(_ logLevel: LogLevel) -> OSLogType {
        switch logLevel {
        case .debug:
            return .debug
        case .default:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        case .info:
            return .info
        case .verbose:
            return .info
        }
    }
    
}
