//
//  GateViewModel.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import Foundation

class GateAppViewModel: ObservableObject {

    static let shared = GateAppViewModel()
    static let sharedDefaultsSuiteName = "group.gateapp"

    // Persisted to the shared app group so the Siri Shortcuts extension can
    // authenticate its own gate requests without duplicating sign-in state.
    @Published var signedIn: User? {
        didSet {
            let defaults = UserDefaults(suiteName: Self.sharedDefaultsSuiteName)
            if let signedIn {
                defaults?.setValue(signedIn.username, forKey: "username")
                defaults?.setValue(signedIn.pin, forKey: "pin")
            } else {
                defaults?.removeObject(forKey: "username")
                defaults?.removeObject(forKey: "pin")
            }
        }
    }

    @Published var mainGate: GateModel
    @Published var clubhouseGate: GateModel
    @Published var testGate: GateModel
    
    init() {
        self.mainGate = GateModel(
            displayName: "Main Gate",
            apiName: "main",
            status: .unknown,
            skipCounter: 0
        )
        self.clubhouseGate = GateModel(
            displayName: "Clubhouse Gate",
            apiName: "clubhouse",
            status: .unknown,
            skipCounter: 0
        )
        self.testGate = GateModel(
            displayName: "Test Gate",
            apiName: "test",
            status: .unknown,
            skipCounter: 0
        )
    }
}
