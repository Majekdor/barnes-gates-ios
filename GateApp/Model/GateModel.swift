//
//  GateModel.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import Foundation
import SwiftUI

struct GateModel {
    var displayName: String
    var apiName: String
    var status: GateStatus
    var skipCounter: Int
}

enum GateStatus {
    case open
    case closed
    case unknown
    
    func status() -> String {
        switch self {
        case .open:
            return "Open"
        case .closed:
            return "Closed"
        case .unknown:
            return "Unknown"
        }
    }
    
    func color() -> Color {
        switch self {
        case .open:
            return .green
        case .closed:
            return .red
        case .unknown:
            return .blue
        }
    }
}
