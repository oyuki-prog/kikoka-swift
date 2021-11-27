//
//  StoreQuestionViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess


class StoreQuestionViewController: UIViewController {
    let consts = Constants.shared
    var token = ""
    var multiple: Decimal = 1.1
    
    var question: Question?
    
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var rewardField: UITextField!
    @IBOutlet weak var urgentSwitch: UISwitch!
    @IBOutlet weak var payLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bodyTextView.layer.borderWidth = 2
        bodyTextView.layer.borderColor = UIColor.systemGray.cgColor
        bodyTextView.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func rewardFieldChanged(_ sender: Any) {
        calcPay()
    }
    
    @IBAction func urgentButtonChanged(_ sender: Any) {
        calcPay()
    }
    
    @IBAction func pressPostPutton(_ sender: Any) {
        postQuestion()
    }
    
    func calcPay() {
        if rewardField.text! != "" {
            if urgentSwitch.isOn == true {
                let decimal = Decimal(string: rewardField.text!)! * 1.2
                payLabel.text = "\(decimal)"
            } else {
                let decimal = Decimal(string: rewardField.text!)! * 1.1
                payLabel.text = "\(decimal)"
            }
        } else {
            payLabel.text = ""
        }

    }
    
    func postQuestion() {
        let keychain = Keychain(service: self.consts.service)
        guard let token = keychain["access_token"] else {return}
        let date = dueDatePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let due_date = dateFormatter.string(from: date)
        let url = URL(string: consts.baseUrl + "/questions")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: Parameters = [
            "title": titleField.text!,
            "body": bodyTextView.text!,
            "due_date": due_date,
            "reward_coin": rewardField.text!,
            "urgent": urgentSwitch.isOn,
            "coin": payLabel.text!
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.question = Question(id: json["question"]["id"].int!,
                                         title: json["question"]["title"].string!,
                                         body: json["question"]["body"].string!,
                                         urgent: json["question"]["urgent"].int!,
                                         elapsed: json["question"]["elapsed"].string!,
                                         reward_coin: Int(json["question"]["reward_coin"].string!)!,
                                         user: User(id: json["question"]["user"]["id"].int!,
                                                    name: json["question"]["user"]["name"].string!))
                let showVC = self.storyboard?.instantiateViewController(withIdentifier: "showVC") as! ShowViewController
                showVC.question = self.question
                self.present(showVC, animated: true, completion: nil)
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}
