//
//  ContentView.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/16/23.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var vm = GateAppViewModel.shared
    
    var body: some View {
        Group {
            if let signedIn = vm.signedIn {
                ControlPanel(signedIn: signedIn)
            } else if let _ = UserDefaults.standard.string(forKey: "username"), let _ = UserDefaults.standard.string(forKey: "pin") {
                ProgressView("Signing in...")
            } else {
                SignInView()
            }
        }
        .task {
            if let username = UserDefaults.standard.string(forKey: "username"), let pin = UserDefaults.standard.string(forKey: "pin") {
                switch await Api.signIn(username: username, pin: pin) {
                case .success(let success):
                    GateAppViewModel.shared.signedIn = success
                case .failure(let failure):
                    print("Sign in using existing username and pin failed: \(failure)")
                    UserDefaults.standard.setValue(nil, forKey: "username")
                    UserDefaults.standard.setValue(nil, forKey: "pin")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
