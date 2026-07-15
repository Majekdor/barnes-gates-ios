//
//  ApiError.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/16/23.
//

import Foundation

/// An API error that could occur during a request.
public enum ApiError: Error {
    
    /// The API request returned a non 200 status code.
    case badStatusCode
    /// The API request response was not of json type.
    case badResponseType
    /// The url provided for the API request was not valid.
    case badURL
    /// The API request did not have the proper authorization.
    case unauthorized
    /// Failed to decode the response provided by the API request.
    case decodeFailed
    /// Failed to encode the request body provided.
    case encodeFailed
    /// Failed to execute URL request.
    case requestFailed
    
    public var description: String {
        switch self {
        case .badStatusCode:
            return "Status code is not 200-299."
        case .badResponseType:
            return "Response is not in JSON form."
        case .badURL:
            return "Could not resolve endpoint url."
        case .unauthorized:
            return "Request did not have the proper authorization."
        case .decodeFailed:
            return "Failed to decode the API response."
        case .encodeFailed:
            return "Failed to encode the provided request body."
        case .requestFailed:
            return "The URL request failed."
        }
    }
}
