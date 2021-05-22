//
//  Message.swift
//  TP_MessageRoom
//
//  Created by Admin on 30.04.2021.
//

import Foundation
import SwiftyJSON

class Message {
    var type: MessageType!
    var content: String!
    var senderId: Int! = -1
    var chatRoomId: Int64!
    
    internal init(type: MessageType!, content: String!, senderId: Int!, chatRoomId: Int64!) {
        self.type = type
        self.content = content
        self.senderId = senderId
        self.chatRoomId = chatRoomId
    }

    init(json: JSON) {
        self.type = MessageType(rawValue: json["type"].rawValue as! String)
        self.content = json["content"].rawValue as? String
        self.senderId = json["senderId"].rawValue as? Int
        self.chatRoomId =  json["chatRoomId"].rawValue as? Int64
    }

    public func toJSON() -> String {
        var json: String = "{\"type\":\"" + type.rawValue + "\",\"content\":\""
            json += content + "\", \"senderId\":\"" + String(senderId)
            json += "\", \"chatRoomId\":\"" + String(chatRoomId) + "\"}"
        return json
    }
}
