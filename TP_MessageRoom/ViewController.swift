//
//  ViewController.swift
//  TP_MessageRoom
//
//  Created by Admin on 22.04.2021.
//

import StompClientLib
import UIKit
import SwiftyJSON

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StompClientLibDelegate {
    var messages: [String] = []
    let MAX_USERS: Int = 5
    // web-socket part
    var socketClient = StompClientLib()
    let url = URL(string: "ws://guesspic.herokuapp.com/chat-example/websocket/")!
   // let url = URL(string: "ws://192.168.159.1:8080/chat-example/websocket/")!
   
    var subscribePath = "/topic/public"
    var sendMessagePath = "/app/chat.send"
    
    var lastPoint : CGPoint?
    var drawingColor = UIColor.black
    let canvasWidth = 5.0
    
    var user: User!
    var users: [User]! = []
    
    @IBOutlet weak var scoreTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonMessage: UIButton!
    @IBOutlet weak var lableMassege: UILabel!
    @IBOutlet weak var guessLabel: UILabel!
    
    @IBOutlet weak var canvas: UIImageView!
    
    
    func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, akaStringBody stringBody:
            String?, withHeader header: [String : String]?, withDestination destination: String) {
        print("Destination : \(destination)")
        print("JSON Body : \(String(describing: jsonBody))")
        
        let jsonDict = (jsonBody as? [String:AnyObject])
        let socketMsg = Message(type: MessageType(rawValue: (jsonDict!["type"] as! String)), content: (jsonDict!["content"] as! String),
                                senderId: (jsonDict!["senderId"] as! Int), chatRoomId: (jsonDict!["chatRoomId"] as! Int64))
        
        if socketMsg.chatRoomId == user.roomId {
            if socketMsg.type == MessageType.CHAT {
                var name: String = ""
                for user in users {
                    if user.id == socketMsg.senderId {
                        name = user.name
                    }
                }
                messages.append(name + ": " + socketMsg.content)
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .automatic)
                tableView.endUpdates()

                let indexPath = NSIndexPath(item: messages.count - 1, section: 0)
                tableView.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            } else if socketMsg.type == MessageType.CONNECT {
                let newUserJSON = socketMsg.content.data(using: .utf8)!
                do {
                    let newUser = try JSONDecoder().decode(User.self, from: newUserJSON)
                    if (newUser.score == nil) {
                        newUser.score = 0
                    }
                    users.append(newUser)
                                       
                    scoreTableView.beginUpdates()
                    scoreTableView.insertRows(at: [IndexPath(row: users.count - 1, section: 0)], with: .automatic)
                    scoreTableView.endUpdates()
                } catch let error as NSError {
                    print(error)
                }
            } else if socketMsg.type == MessageType.WIN {
                lastPoint = nil
                do {
                    canvas.image = UIImage()
                    
                    let winInfoMsg = socketMsg.content.data(using: .utf8)!
                    if let json = try JSONSerialization.jsonObject(with: winInfoMsg, options: []) as? [String: AnyObject] {
                        let winInfo = WinInfo(winnerId: (Int(json["winnerId"] as! String)!),
                                              bonus: (Int(json["bonus"] as! String)!),
                                              nextPainterId: (Int(json["nextPainterId"] as! String)!))
                        if user.isPainter {
                            user.isPainter = false
                            scrollView.isUserInteractionEnabled = true
                        } else if winInfo.nextPainterId == user.id {
                            user.isPainter = true
                            scrollView.isUserInteractionEnabled = false
                        }
                        for i in 0...users.count - 1 {
                            if users[i].id == winInfo.nextPainterId {
                                users[i].isPainter = true
                            }
                            if users[i].id == winInfo.winnerId {
                                users[i].score += winInfo.bonus
                                let indexPath = IndexPath(row: i, section: 0)
                                let cell = scoreTableView.cellForRow(at: indexPath)
                                cell!.detailTextLabel?.text = String(users[i].score!)
                            }
                        }
                    }
                    updateGuessLabel()
                } catch {
                    print("parse error")
                }
            } else if !user.isPainter && socketMsg.type == MessageType.UPDATE_CANVAS {
                let currPoint = NSCoder.cgPoint(for: socketMsg.content)
                paintDiff(currentPoint: currPoint)
            } else if socketMsg.type == MessageType.DISCONNECT {
                let disconId = Int(socketMsg.senderId)
                if disconId == user.id {
                    guessLabel.text = "GOODBYE!"
                    scrollView.isUserInteractionEnabled = true
                    socketClient.disconnect()
                }
                
                for i in 0...users.count-1 {
                    if users[i].id == disconId {
                        if i != users.count-1 {
                            for j in i...users.count - 2 {
                                users[j] = users[j + 1]
                                let indexPath = IndexPath(row: j, section: 0)
                                let cell = scoreTableView.cellForRow(at: indexPath)
                                cell!.textLabel?.text = users[j].name
                                cell!.detailTextLabel?.text = String(users[j].score!)
                            }
                        }
                        let indexPath = IndexPath(row: users.count-1, section: 0)
                        let cell = scoreTableView.cellForRow(at: indexPath)
                        
                        users.remove(at: users.count - 1)
                        scoreTableView.deleteRows(at: [indexPath], with: .fade)

                        break
                    }
                }
            } else if socketMsg.type == MessageType.INIT_WORD_AND_PAINTER {
                canvas.image = UIImage()
                let nextPainterId = Int(socketMsg.content)
                if nextPainterId == user.id {
                    user.isPainter = true
                    scrollView.isUserInteractionEnabled = false
                }
                updateGuessLabel()
            } else if socketMsg.type == MessageType.RAISE_PEN {
                lastPoint = NSCoder.cgPoint(for: socketMsg.content)
            }
            
        }
    }
    
    func stompClientJSONBody(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
      print("stompClientJSONBody log..")
    }
    
    func stompClientDidDisconnect(client: StompClientLib!) {
        socketClient.unsubscribe(destination: subscribePath)
        print("Socket disconnected")
    }
    
    func stompClientDidConnect(client: StompClientLib!) {
        print("Socket connected!")
        socketClient.subscribe(destination: subscribePath)
        var areUsersCaught = false
        
        // 192.168.159.1:8080
        // https://guesspic.herokuapp.com
        guard let url = URL(string: "https://guesspic.herokuapp.com/update_users/\(String(describing: user.roomId!))/") else {
            print("INCORRECT URL!")
            return
        }
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let decoder = JSONDecoder()
                let users: [User] = try decoder.decode([User].self, from: data!)
                for user in users {
                    self.users.append(user)
                }
                areUsersCaught = true
            } catch let parseError {
                print("JSON Error \(parseError.localizedDescription)")
            }
        }
        task.resume()
        
        while !areUsersCaught { }
        
        self.tableView.estimatedRowHeight = 44.0
        registerForKeyboardNotifications()
        
        if self.user.isPainter {
            scrollView.isUserInteractionEnabled = false
        } else {
            scrollView.isUserInteractionEnabled = true
        }

        if users.count > 0 {
            scoreTableView.beginUpdates()
            for i in 0...users.count - 1 {
                scoreTableView.insertRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
            }
            scoreTableView.endUpdates()
        }
        self.message.isEditable = true
    }
    
    func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
        print("serverDidSendReceipt")
    }
    
    func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
        print("Server send error : " + String(describing: message))

    }
    
    func serverDidSendPing() {
        print("serverDidSendPing")
    }
    // end web-socket part
    
    override func viewDidLoad() {
        super.viewDidLoad()
        message.isEditable = false
        socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url), delegate: self)
        
        // waiting for user to be caught from server
        while user == nil { }
        
        self.subscribePath = "/topic/public" + "/" + String(user.roomId)
        self.sendMessagePath = "/app/" + String(user.roomId) + "/chat.send"
        print("subscribePath: ", subscribePath)
        print("sendMessagePath: ", sendMessagePath)
        
        updateGuessLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            if user.isPainter {
                user.isPainter = false
                scrollView.isUserInteractionEnabled = true
            }
            let msg = Message(type: MessageType.DISCONNECT,
                              content: "",
                              senderId: user.id,
                              chatRoomId: user.roomId)
            socketClient.sendMessage(message: msg.toJSON(), toDestination: sendMessagePath, withHeaders: nil, withReceipt: nil)
            socketClient.disconnect()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        lastPoint = (touch?.location(in: self.canvas))!
        socketClient.sendMessage(message: Message(type: MessageType.RAISE_PEN,
                                                  content: NSCoder.string(for: lastPoint!),
                                                  senderId: user.id,
                                                  chatRoomId: user.roomId).toJSON(),
                                 toDestination: sendMessagePath, withHeaders: nil, withReceipt: nil)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let currentPoint = (touch?.location(in: self.canvas))!
        paintDiff(currentPoint: currentPoint)
        
        let msg = Message(type: MessageType.UPDATE_CANVAS,
                          content: NSCoder.string(for: currentPoint),
                          senderId: user.id,
                          chatRoomId: user.roomId)
        
        socketClient.sendMessage(message: msg.toJSON(), toDestination: sendMessagePath, withHeaders: nil, withReceipt: nil)
    }
    
    func paintDiff(currentPoint: CGPoint) {
        if lastPoint == nil {
            lastPoint = currentPoint
        }
        
        UIGraphicsBeginImageContext(self.canvas.frame.size)
        let drawRect = CGRect.init(x: 0.0, y: 0.0, width: self.canvas.frame.width, height: self.canvas.frame.height)
        self.canvas.image?.draw(in: drawRect)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(drawingColor.cgColor)
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(CGFloat(canvasWidth))
        context?.beginPath()
        context?.move(to: lastPoint!)
        context?.addLine(to: currentPoint)
        context?.strokePath()
        self.canvas.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        lastPoint = currentPoint
    }
    
    func updateGuessLabel() {
        if user.isPainter {
            var word: String = ""
            // https://guesspic.herokuapp.com
            // 192.168.159.1:8080
            guard let url = URL(string: "https://guesspic.herokuapp.com/room/\(String(describing: user.roomId!))/user/\(String(describing: user.id!))/word/") else {
                print("INCORRECT URL!")
                return
            }
            var request = URLRequest(url: url)

            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    print("WORD FROM SERVER: " + word)
                    word = String(data: data!, encoding: .utf8)!
                }
            }
            task.resume()
            while word == "" { }
            guessLabel.text = word
        }
        else {
            guessLabel.text = ""
        }
    }
    
    @IBAction func buttonMessageClick(_ sender: Any) {
        if message.text != "" {
            // web-socket
            do {
                let sendingMessage = Message(type: MessageType.CHAT,
                                             content: message.text!,
                                             senderId: user.id,
                                             chatRoomId: user.roomId)
                socketClient.sendMessage(message: sendingMessage.toJSON(),
                                         toDestination: sendMessagePath,
                                         withHeaders: nil,
                                         withReceipt: nil)
            }
            message.text = ""
        }
        message.resignFirstResponder()
        buttonMessage.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return messages.count
        }
        else{
            return users.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 0.2
            cell.layer.cornerRadius = 12
            cell.clipsToBounds = true
            cell.textLabel?.text = messages[indexPath.row]
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellScore", for: indexPath)
            
            cell.textLabel?.text = users[indexPath.row].name
            cell.detailTextLabel?.text = String(users[indexPath.row].score)
            return cell
        }
    }
    deinit {
        removeKeyboardNotifications()
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
        
    @objc func kbWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        scrollView.contentOffset = CGPoint(x: 0, y: kbFrameSize.height - 29)
    }
    
    @objc func kbWillHide() {
        scrollView.contentOffset = CGPoint.zero
    }
}
