//
//  SettingsSheet.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import SwiftUI

struct SettingsSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var gateAppViewModel: GateAppViewModel
    
    @State private var allUsers: [User] = []
    @State private var showCreateNewUserSheet: Bool = false
    @State private var editingUser: User?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(allUsers) { user in
                        CardView {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(user.username)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button(
                                        action: {
                                            editingUser = user
                                        },
                                        label: {
                                            Image(systemName: "pencil.circle")
                                        }
                                    )
                                    .tint(.orange)
                                    
                                    if !user.admin {
                                        Button(
                                            action: {
                                                Task {
                                                    switch await Api.deleteUserByUsername(user.username) {
                                                    case .success(let success):
                                                        if !success.deleted {
                                                            print("Failed to delete user \(user.username)")
                                                        }
                                                    case .failure(let failure):
                                                        print("Failed to delete user \(user.username): \(failure)")
                                                    }
                                                    
                                                    switch await Api.getUsers() {
                                                    case .success(let success):
                                                        allUsers = success
                                                    case .failure(let failure):
                                                        print("Failed to get all users: \(failure)")
                                                    }
                                                }
                                            },
                                            label: {
                                                Image(systemName: "trash")
                                            }
                                        )
                                        .tint(.red)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Button(
                        action: {
                            showCreateNewUserSheet = true
                        },
                        label: {
                            Text("Create New User")
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            dismiss()
                        },
                        label: {
                            Text("Done")
                        }
                    )
                }
            }
            .sheet(isPresented: $showCreateNewUserSheet) {
                ModifyUserSheet(
                    creatingNewUser: true,
                    allUsers: $allUsers
                )
            }
            .sheet(item: $editingUser) { user in
                ModifyUserSheet(
                    creatingNewUser: false,
                    allUsers: $allUsers,
                    user: user
                )
            }
        }
        .task {
            switch await Api.getUsers() {
            case .success(let success):
                allUsers = success
            case .failure(let failure):
                print("Failed to get all users: \(failure)")
            }
        }
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                SettingsSheet()
                    .environmentObject(GateAppViewModel.shared)
            }
    }
}
