//
//  GateInfoView.swift
//  GateApp
//
//  Created by Kevin Barnes on 12/4/22.
//

import SwiftUI

struct GateInfoView: View {
    
    @Binding var gate: GateModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(gate.displayName)
                .font(.title)
                .fontWeight(.heavy)
            
            HStack {
                Text("Status: ")
                
                Text(self.gate.status.status())
                    .foregroundColor(self.gate.status.color())
                    .fontWeight(.bold)
                    .underline()
            }
            
            if GateAppViewModel.shared.signedIn?.admin ?? false || GateAppViewModel.shared.signedIn?.trusted ?? false {
                HStack {
                    Button(action: {
                        // haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        // open the gate
                        Task {
                            switch await Api.openGate(self.gate.apiName) {
                            case .success:
                                break
                            case .failure(let failure):
                                print("Failed to open gate: \(failure)")
                            }
                        }
                    }, label: {
                        Text("Open")
                            .font(.title3)
                            .frame(width: 80, height: 25)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)

                    Button(action: {
                        // haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        // close the gate
                        Task {
                            switch await Api.closeGate(self.gate.apiName) {
                            case .success:
                                break
                            case .failure(let failure):
                                print("Failed to close gate: \(failure)")
                            }
                        }
                    }, label: {
                        Text("Close")
                            .font(.title3)
                            .frame(width: 80, height: 25)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                
                HStack {
                    Text("Skip Counter:")
                    
                    Text("\(self.gate.skipCounter)")
                        .fontWeight(.bold)
                }
            } else {
                Button(action: {
                    // haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    Task {
                        switch await Api.openGate(self.gate.apiName) {
                        case .success:
                            break
                        case .failure(let failure):
                            print("Failed to open gate: \(failure)")
                        }

                        switch await Api.closeGate(self.gate.apiName) {
                        case .success:
                            break
                        case .failure(let failure):
                            print("Failed to close gate: \(failure)")
                        }
                    }
                }, label: {
                    Text("Open")
                        .font(.title3)
                        .frame(width: 80, height: 25)
                })
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
    }
}

struct GateInfoView_Previews: PreviewProvider {
    static var previews: some View {
        GateInfoView(
            gate: .constant(
                GateModel(
                    displayName: "Main Gate",
                    apiName: "main",
                    status: .unknown,
                    skipCounter: 0
                )
            )
        )
    }
}
