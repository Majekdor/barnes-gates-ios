//
//  ControlPanel.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import EventSource
import Foundation
import SwiftUI

struct ControlPanel: View {
    
    let signedIn: User
    
    @StateObject private var gateAppViewModel: GateAppViewModel = GateAppViewModel.shared
    
    @State private var showSettingsSheet: Bool = false
    
    @State private var eventSource: EventSource? = nil
    @State private var currentId: String? = nil
    @State private var skips: String = "1"
    
    @FocusState private var skipControlFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Divider()
                    .padding()
                
                if signedIn.mainGate {
                    Group {
                        GateInfoView(gate: self.$gateAppViewModel.mainGate)
                        
                        Divider()
                            .padding()
                    }
                }
                
                if signedIn.clubhouseGate {
                    Group {
                        GateInfoView(gate: self.$gateAppViewModel.clubhouseGate)
                        
                        Divider()
                            .padding()
                    }
                }
                
//                #if DEBUG
//                
//                Group {
//                    GateInfoView(gate: self.$gateAppViewModel.testGate)
//                    
//                    Divider()
//                        .padding()
//                }
//                
//                #endif
                
                if signedIn.admin || signedIn.trusted {
                    Group {
                        Text("Skip Control")
                            .font(.title)
                            .fontWeight(.heavy)
                        
                        HStack(spacing: 15) {
                            TextField("Skips", text: self.$skips)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .focused($skipControlFocused)
                                .frame(maxWidth: 60)
                            
                            Button(
                                action: {
                                    skipControlFocused = false

                                    Task {
                                        switch await Api.skipGate(count: self.skips) {
                                        case .success:
                                            break
                                        case .failure(let failure):
                                            print("Failed to send skip command: \(failure)")
                                        }
                                    }
                                },
                                label: {
                                    Text("Send")
                                        .font(.title3)
                                }
                            )
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        
                        Divider()
                            .padding()
                    }
                }
                
                Text("Update Status")
                    .font(.title)
                    .fontWeight(.heavy)
                
                Button(action: {
                    // haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    Task {
                        await self.openConnection()
                        if eventSource != nil {
                            switch await Api.refreshGateStatus() {
                            case .success:
                                break
                            case .failure(let failure):
                                print("Failed to refresh gate status: \(failure)")
                            }
                        }
                    }
                }, label: {
                    Text("Update")
                        .font(.title3)
                })
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.bottom, 50)
            }
            .navigationTitle("Gate Control")
            .toolbar {
                if signedIn.admin {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(
                            action: {
                                showSettingsSheet = true
                            },
                            label: {
                                Text("Admin")
                            }
                        )
                        .tint(.accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            GateAppViewModel.shared.signedIn = nil
                            UserDefaults.standard.setValue(nil, forKey: "username")
                            UserDefaults.standard.setValue(nil, forKey: "pin")
                        },
                        label: {
                            Text("Sign Out")
                        }
                    )
                    .tint(.red)
                }
            }
            .sheet(isPresented: self.$showSettingsSheet) {
                SettingsSheet()
                    .environmentObject(self.gateAppViewModel)
            }
        }
        .onAppear {
            Task {
                await self.openConnection()
            }
        }
    }
    
    /// Open a connection to the backend to receive server sent events regarding each gate's status.
    func openConnection() async {
        if self.eventSource != nil {
            return
        }

        let url = URL(string: "\(Constants.BASE_URL)/gates/events")!

        eventSource = EventSource(url: url)
        eventSource?.connect()

        eventSource?.onComplete({ (statusCode, reconnect, error) in
            eventSource?.connect(lastEventId: currentId);
        })

        eventSource?.onOpen {
            print("Event sourced opened!")

            Task {
                switch await Api.refreshGateStatus() {
                case .success:
                    break
                case .failure(let failure):
                    print("Failed to refresh gate status: \(failure)")
                }
            }
        }

        eventSource?.addEventListener("main_gate_1") { (id, event, data) in
            processedReceivedData(gate: &self.gateAppViewModel.mainGate, data: data)
        }
        
        eventSource?.addEventListener("clubhouse_gate_1") { (id, event, data) in
            processedReceivedData(gate: &self.gateAppViewModel.clubhouseGate, data: data)
        }
        
        #if DEBUG
        
        eventSource?.addEventListener("gatetest_1") { (id, event, data) in
            processedReceivedData(gate: &self.gateAppViewModel.testGate, data: data)
        }
        
        #endif
    }

    /// Process data received in an event listener.
    /// - `gate`: The gate that should be updated based on the data.
    /// - `data`: The data that was recevied.
    func processedReceivedData(gate: inout GateModel, data: String?) {
        guard let dataString = data else {
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: dataString.data(using: .utf8)!) as! [String : Any]
            let status = jsonObject["data"] ?? "not found"

            print("Status: \(status)")
            guard let statusString = status as? String else {
                return
            }
            
            if statusString.contains("ON") {
                gate.status = .open
                if statusString.count > 2 {
                    let numChar: Character = statusString[statusString.index(statusString.startIndex, offsetBy: 3)]
                    if let skipCounter = Int(String(numChar)) {
                        gate.skipCounter = skipCounter
                    }
                }
            } else if statusString.contains("OFF") {
                gate.status = .closed
                if statusString.count > 3 {
                    let numChar: Character = statusString[statusString.index(statusString.startIndex, offsetBy: 4)]
                    print(numChar)
                    if let skipCounter = Int(String(numChar)) {
                        gate.skipCounter = skipCounter
                    }
                }
            } else {
                gate.status = .unknown
            }
            
            // haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct ControlPanel_Previews: PreviewProvider {
    static var previews: some View {
        ControlPanel(
            signedIn: User(
                _id: "doesn't matter",
                username: "kevin",
                pin: "0000",
                mainGate: true,
                clubhouseGate: true,
                admin: false,
                trusted: true
            )
        )
    }
}
