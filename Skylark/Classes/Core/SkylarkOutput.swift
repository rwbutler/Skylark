//
//  SkylarkOutput.swift
//  Skylark
//
//  Created by Ross Butler on 6/25/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

import Foundation

/// Sinks to which test reports are sent.
public enum SkylarkOutput {
    case debugPrint
    case print
    case slack(webhookURL: URL)
}
