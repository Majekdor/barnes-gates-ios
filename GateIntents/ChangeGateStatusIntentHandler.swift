//
//  ChangeGateStatusIntentHandler.swift
//  GateIntents
//
//  Created by Kevin Barnes on 12/29/22.
//

import Foundation
import Intents

class ChangeGateStatusIntentHandler: INExtension, ChangeGateStatusIntentHandling {
    
    @MainActor func handle(intent: ChangeGateStatusIntent, completion: @escaping (ChangeGateStatusIntentResponse) -> Void) {
        var response: ChangeGateStatusIntentResponse
        switch (intent.gate) {
        case .unknown:
            response = ChangeGateStatusIntentResponse(code: .failure, userActivity: nil)
        case .main:
            Task {
                await setGateState(gate: "main", open: intent.status != 0)
            }
            response = ChangeGateStatusIntentResponse(code: .success, userActivity: nil)
            response.status = intent.status
            response.gate = intent.gate
        case .clubhouse:
            Task {
                await setGateState(gate: "clubhouse", open: intent.status != 0)
            }
            response = ChangeGateStatusIntentResponse(code: .success, userActivity: nil)
            response.status = intent.status
            response.gate = intent.gate
        }
        completion(response)
    }
    
    func resolveGate(for intent: ChangeGateStatusIntent, with completion: @escaping (GateResolutionResult) -> Void) {
        var result: GateResolutionResult
        if intent.gate != .unknown {
            result = GateResolutionResult.success(with: intent.gate)
        } else {
            result = GateResolutionResult.needsValue()
        }
        completion(result)
    }
    
    func resolveStatus(for intent: ChangeGateStatusIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        var result: INBooleanResolutionResult
        if let bool = intent.status {
            result = INBooleanResolutionResult.success(with: bool != 0)
        } else {
            result = INBooleanResolutionResult.needsValue()
        }
        completion(result)
    }
    
    /// Open or close a gate via the backend, using the signed-in credentials
    /// shared with the main app through the app group.
    /// - `gate`: The backend gate identifier ("main" or "clubhouse")
    /// - `open`: Whether the gate should be opened or closed
    func setGateState(gate: String, open: Bool) async {
        guard let defaults = UserDefaults(suiteName: "group.gateapp"),
              let username = defaults.string(forKey: "username"),
              let pin = defaults.string(forKey: "pin") else {
            print("No signed-in credentials available in the shared app group.")
            return
        }

        let url = URL(string: "\(Constants.BASE_URL)/gates/\(gate)/\(open ? "open" : "close")")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "username": username,
            "pin": pin
        ])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print(String(data: data, encoding: .utf8) ?? "Unable to unwrap data response.")
        } catch {
            print(error.localizedDescription)
        }
    }
}
