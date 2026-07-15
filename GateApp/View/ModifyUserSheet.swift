//
//  ModifyUserSheet.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/17/23.
//

import SwiftUI

struct ModifyUserSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let creatingNewUser: Bool
    @Binding var allUsers: [User]
    
    @State var user: User = User(
        _id: "foo",
        username: "",
        pin: "",
        mainGate: false,
        clubhouseGate: false,
        admin: false,
        trusted: false
    )
    
    @State private var originalUsername: String = ""
    @State private var trustedInfoAlert: Bool = false
    @State private var failedToModifyUser: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    TextField("Username", text: $user.username)
                    
                    TextField("PIN", text: $user.pin)
                        .keyboardType(.numberPad)
                    
                    Toggle(
                        isOn: $user.trusted,
                        label: {
                            HStack {
                                Text("Trusted User")
                                
                                Button(
                                    action: {
                                        trustedInfoAlert = true
                                    },
                                    label: {
                                        Image(systemName: "info.circle")
                                            .font(.title2)
                                    }
                                )
                                .alert(
                                    "Trusted User",
                                    isPresented: $trustedInfoAlert,
                                    actions: {},
                                    message: {
                                        Text("Trusted users can use skip control and hold gates opened or closed.")
                                    }
                                )
                            }
                        }
                    )
                    .onChange(of: user.trusted) { newValue in
                        if newValue {
                            user.mainGate = true
                            user.clubhouseGate = true
                        }
                    }
                    
                    Button(
                        action: {
                            withAnimation {
                                user.mainGate.toggle()
                            }
                        },
                        label: {
                            Group {
                                if user.mainGate {
                                    Text("CAN Open Main Gate")
                                } else {
                                    Text("CANNOT Open Main Gate")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .tint(user.mainGate ? .green : .red)
                    .disabled(user.trusted)
                    
                    Button(
                        action: {
                            withAnimation {
                                user.clubhouseGate.toggle()
                            }
                        },
                        label: {
                            Group {
                                if user.clubhouseGate {
                                    Text("CAN Open Clubhouse Gate")
                                } else {
                                    Text("CANNOT Open Clubhouse Gate")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .tint(user.clubhouseGate ? .green : .red)
                    .disabled(user.trusted)
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .padding()
            }
            .navigationTitle("\(creatingNewUser ? "Create New" : "Update") User")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            Task { @MainActor in
                                if creatingNewUser {
                                    switch await Api.createUser(user) {
                                    case .success(let success):
                                        allUsers.append(success)
                                        dismiss()
                                    case .failure(let failure):
                                        failedToModifyUser = true
                                        print("Failed to create new user: \(failure)")
                                    }
                                } else {
                                    switch await Api.updateUser(username: originalUsername, user: user) {
                                    case .success(let success):
                                        if let index = allUsers.firstIndex(where: { $0.id == user.id }) {
                                            allUsers[index] = success
                                        }
                                        dismiss()
                                    case .failure(let failure):
                                        failedToModifyUser = true
                                        print("Failed to update user: \(failure)")
                                    }
                                }
                            }
                        },
                        label: {
                            Text(creatingNewUser ? "Create" : "Update")
                        }
                    )
                    .disabled(user.username.isEmpty || user.pin.isEmpty)
                }
            }
        }
        .onAppear {
            originalUsername = user.username
        }
        .sheet(isPresented: $failedToModifyUser) {
            VStack {
                Text("Failed to \(creatingNewUser ? "create new" : "update") user. The username might be taken.")
                    .padding()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.15)])
                
                Spacer()
            }
        }
    }
}

struct CreateNewUserSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                ModifyUserSheet(creatingNewUser: true, allUsers: .constant([]))
                    .environmentObject(GateAppViewModel.shared)
            }
        
        Text("")
            .sheet(isPresented: .constant(true)) {
                ModifyUserSheet(creatingNewUser: false, allUsers: .constant([]))
                    .environmentObject(GateAppViewModel.shared)
            }
    }
}
