//
//  Extensions.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/17/22.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
extension View {
    @available(iOSApplicationExtension, unavailable)
    func hideKeyboard() {
        if !Bundle.main.bundlePath.hasSuffix(".appex") {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
#endif
