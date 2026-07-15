//
//  GateApp.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import Intents
import SwiftUI

@main
struct GateApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { phase in
                    INPreferences.requestSiriAuthorization({ status in
                        // Handle errors here
                    })
                }
        }
    }
}
