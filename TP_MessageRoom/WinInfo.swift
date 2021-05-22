//
//  WinInfo.swift
//  TP_MessageRoom
//
//  Created by Admin on 05.05.2021.
//

import Foundation

class WinInfo : Codable {
    var winnerId: Int!
    var bonus: Int!
    var nextPainterId: Int!
    
    internal init(winnerId: Int!, bonus: Int!, nextPainterId: Int!) {
        self.winnerId = winnerId
        self.bonus = bonus
        self.nextPainterId = nextPainterId
    }
}
