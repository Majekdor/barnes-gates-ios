//
//  SignInView.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/16/23.
//

import SwiftUI

struct SignInView: View {
    
    @State private var username: String = ""
    @State private var pin: String = ""
    @State private var signingIn: Bool = false
    @State private var signInFailed: Bool = false
    
    @FocusState private var passwordIsFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Barnes Gates")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please sign in with your username and pin")
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .onSubmit {
                            passwordIsFocused = true
                        }
                    
                    TextField("PIN", text: $pin)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .keyboardType(.numberPad)
                        .focused($passwordIsFocused)
                        .onSubmit {
                            Task {
                                await signIn()
                            }
                        }
                }
                
                Button(
                    action: {
                        Task {
                            await signIn()
                        }
                    },
                    label: {
                        Text("Sign In")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                )
                .buttonStyle(.borderedProminent)
                .opacity(username.isEmpty || pin.isEmpty ? 0.0 : 1.0)
                .animation(.default, value: username)
                .animation(.default, value: pin)
                .disabled(signingIn)
                
                if signingIn {
                    ProgressView()
                }
            }
            .padding()
        }
        .sheet(isPresented: $signInFailed) {
            VStack {
                Text("Your username or PIN is incorrect.")
                    .padding()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.1)])
                
                Spacer()
            }
        }
    }
    
    
    @MainActor func signIn() async {
        withAnimation {
            signingIn = true
        }
        
        switch await Api.signIn(username: username, pin: pin) {
        case .success(let success):
            UserDefaults.standard.setValue(username, forKey: "username")
            UserDefaults.standard.setValue(pin, forKey: "pin")
            GateAppViewModel.shared.signedIn = success
        case .failure(let failure):
            signInFailed = true
            print("Failed to sign in: \(failure)")
        }
        
        signingIn = false
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
