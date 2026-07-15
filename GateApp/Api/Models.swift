//
//  Models.swift
//  GateApp
//
//  Created by Kevin Barnes on 11/16/23.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String { _id }
    var _id: String
    var username: String
    var pin: String
    var mainGate: Bool
    var clubhouseGate: Bool
    var admin: Bool
    var trusted: Bool
}

struct Deleted: Codable {
    var deleted: Bool
}

struct Success: Codable {
    var success: Bool
}

struct CanOpen: Codable {
    var canOpen: Bool
}
