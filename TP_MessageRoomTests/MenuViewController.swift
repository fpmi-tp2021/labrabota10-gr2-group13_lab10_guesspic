//
//  MenuViewController.swift
//  TP_MessageRoom
//
//  Created by Admin on 28.04.2021.
//

import UIKit
import SwiftyJSON

class MenuViewController: UIViewController {
    override func viewDidLoad() {        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func buttonCreateUser(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "GoPlay") as? ViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        var userName: String
        
        if textField.text == "" {
            userName = "User"
        } else {
            userName = textField.text!
        }
        
        // 192.168.159.1:8080
        //https://guesspic.herokuapp.com
        guard let url = URL(string: "https://guesspic.herokuapp.com/new_user/\(userName)/") else {
            print("INCORRECT URL!")
            return
        }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                let json = try JSON(data: data!)
                vc.user = User(name: json["name"].rawValue as? String,
                               id: json["id"].rawValue as? Int,
                               score: json["score"].rawValue as? Int,
                               roomId: json["roomId"].rawValue as? Int64,
                               isPainter: json["painter"].rawValue as? Bool)
            } catch let parseError {
                print("JSON Error \(parseError.localizedDescription)")
            }
        }
        task.resume()
    }
}
