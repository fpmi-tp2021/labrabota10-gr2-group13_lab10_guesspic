//
//  User.swift
//  TP_MessageRoom
//
//  Created by Admin on 03.05.2021.
//

import Foundation

class User : Codable {
    var name: String!
    var id: Int! = -1
    var score: Int!
    var roomId: Int64!
    var isPainter: Bool!
    
    internal init(name: String!, id: Int!, score: Int!, roomId: Int64!, isPainter: Bool!) {
        self.name = name
        self.id = id
        self.score = score
        self.roomId = roomId
        self.isPainter = isPainter
    }
}
