//
//  Api.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/16/23.
//

import Foundation

class Api {
    
    static func createUser(_ user: User) async -> Result<User, ApiError> {
        return await request(
            method: .post,
            path: "/users",
            body: user,
            returnType: User.self
        )
    }
    
    static func getUsers() async -> Result<Array<User>, ApiError> {
        return await request(
            path: "/users/",
            returnType: Array<User>.self
        )
    }
    
    static func getUserByUsername(_ username: String) async -> Result<User, ApiError> {
        return await request(
            path: "/users/\(username)",
            returnType: User.self
        )
    }
    
    static func updateUser(username: String, user: User) async -> Result<User, ApiError> {
        return await request(
            method: .put,
            path: "/users/\(username)",
            body: user,
            returnType: User.self
        )
    }
    
    static func deleteUserByUsername(_ username: String) async -> Result<Deleted, ApiError> {
        return await request(
            method: .delete,
            path: "/users/\(username)",
            returnType: Deleted.self
        )
    }
    
    static func canOpenMainGate(_ username: String) async -> Result<CanOpen, ApiError> {
        return await request(
            path: "/can-open-main-gate/\(username)",
            returnType: CanOpen.self
        )
    }
    
    static func canOpenClubhouseGate(_ username: String) async -> Result<CanOpen, ApiError> {
        return await request(
            path: "/can-open-clubhouse-gate/\(username)",
            returnType: CanOpen.self
        )
    }
    
    static func signIn(username: String, pin: String) async -> Result<User, ApiError> {
        return await request(
            method: .post,
            path: "/sign-in",
            body: [
                "username": username,
                "pin": pin
            ],
            returnType: User.self
        )
    }

    static func openGate(_ gate: String) async -> Result<Success, ApiError> {
        return await request(
            method: .post,
            path: "/gates/\(gate)/open",
            body: credentialsBody(),
            returnType: Success.self
        )
    }

    static func closeGate(_ gate: String) async -> Result<Success, ApiError> {
        return await request(
            method: .post,
            path: "/gates/\(gate)/close",
            body: credentialsBody(),
            returnType: Success.self
        )
    }

    static func skipGate(count: String) async -> Result<Success, ApiError> {
        var body = credentialsBody()
        body["skips"] = count
        return await request(
            method: .post,
            path: "/gates/skip",
            body: body,
            returnType: Success.self
        )
    }

    static func refreshGateStatus() async -> Result<Success, ApiError> {
        return await request(
            method: .post,
            path: "/gates/refresh",
            returnType: Success.self
        )
    }

    private static func credentialsBody() -> [String: String] {
        [
            "username": GateAppViewModel.shared.signedIn?.username ?? "",
            "pin": GateAppViewModel.shared.signedIn?.pin ?? ""
        ]
    }
    
    private static let encoder: JSONEncoder = JSONEncoder()
    private static let decoder: JSONDecoder = JSONDecoder()
    
    private static func request<Return: Codable>(
        method: HttpMethod = .get,
        path: String,
        body: Codable? = nil,
        returnType: Return.Type
    ) async -> Result<Return, ApiError> {
        do {
            guard let url = URL(string: Constants.BASE_URL + path) else {
                return .failure(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            // Set body if necessary
            if let body {
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                    encoder.dateEncodingStrategy = .formatted(dateFormatter)
                    request.httpBody = try encoder.encode(body)
                } catch {
                    return .failure(.encodeFailed)
                }
            }
            
            // Identify the signed-in user so the backend can authorize
            // admin-only actions against their real username/pin.
            if let signedIn = GateAppViewModel.shared.signedIn {
                request.setValue(signedIn.username, forHTTPHeaderField: "X-Username")
                request.setValue(signedIn.pin, forHTTPHeaderField: "X-Pin")
            }
            
            // Set content type
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Execute request
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                    return .failure(.unauthorized)
                }
                // Response was not a 200 code
                return .failure(.badStatusCode)
            }
            
            guard let mimeType = response.mimeType, mimeType == "application/json" else {
                // Response was not of json type
                return .failure(.badResponseType)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            do {
                return try .success(decoder.decode(returnType, from: data))
            } catch {
                return .failure(.decodeFailed)
            }
        } catch {
            return .failure(.requestFailed)
        }
    }
    
    // MARK: Http Method
    
    
    private enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}
