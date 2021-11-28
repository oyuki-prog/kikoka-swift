//
//  RegisterViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess

class RegisterViewController: UIViewController {
    let consts = Constants.shared
    var token = ""
    var nextUrl: String? = ""
    
    var questions: [Question] = []
    
    var nameText: String?
    var emailText: String?
    var passwordText: String?
    var confirmText: String?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var caution: UILabel!
    @IBOutlet weak var emailCaution: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        registerButton.isEnabled = false
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func pressRegisterButton(_ sender: Any) {
        self.getAccessToken()
    }
    
    func getAccessToken() {
        if passwordField.text != confirmField.text {
            return
        }
        let url = URL(string: consts.baseUrl + "/register")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json"
        ]
        let parameters: Parameters = [
            "name": nameField.text!,
            "email": emailField.text!,
            "password": passwordField.text!
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)

                if json["email"][0].string != "" {
                    self.emailCaution.text = json["email"][0].string
                }
                if json["message"].string?.prefix(15) == "SQLSTATE[23000]" {
                    self.emailCaution.text = "このアドレスは登録されています"
                }
                let token: String? = json["token"].string
                guard let accessToken = token else { return }
                self.token = accessToken
                let keychain = Keychain(service: self.consts.service)
                keychain["access_token"] = accessToken
                self.getIndex()
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    func transitionToIndexView() {
        let indexNC = self.storyboard?.instantiateViewController(withIdentifier: "indexNC") as! UINavigationController
        let indexVC = indexNC.viewControllers[0] as! IndexViewController
        indexVC.questions = self.questions
        indexVC.nextUrl = self.nextUrl
        indexNC.modalPresentationStyle = .fullScreen
        present(indexNC, animated: true, completion: nil)
    }
    
    
    @IBAction func nameFieldChanged(_ sender: UITextField) {
        nameText = sender.text
        self.validate()
    }
    
    @IBAction func emailFieldChanged(_ sender: UITextField) {
        emailText = sender.text
        emailCaution.text = ""
        self.validate()
    }
    
    @IBAction func passwordFieldChanged(_ sender: UITextField) {
        passwordText = sender.text
        if passwordText!.count < 8 {
            caution.text = "パスワードは8文字以上に設定してください"
        } else {
            caution.text = ""
        }
        self.validate()
    }
 
    @IBAction func confirmFieldChanged(_ sender: UITextField) {
        confirmText = sender.text
        self.validate()
        self.confirm()
    }
    
    private func validate() {
        guard let name = self.nameText,
              let email = self.emailText,
              let password = self.passwordText,
              let confirm = self.confirmText else {
                  self.registerButton.isEnabled = false
                  return
              }
        
        if name.count == 0 || email.count == 0 || password.count == 0 || confirm.count == 0 {
            self.registerButton.isEnabled = false
            return
        }
              
        self.registerButton.isEnabled = true
    }
    
    func confirm() {
        if (passwordText != confirmText && confirmText!.count != 0) {
            caution.text = "確認用パスワードが一致しません"
            self.registerButton.isEnabled = false
        } else {
            caution.text = ""
        }
    }
    
    func getIndex() {
        let url = URL(string: consts.baseUrl + "/questions")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json",
        ]

        AF.request(url, method: .get, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                for question in json["questions"]["data"].arrayValue {
                    self.questions.append(Question(id: question["id"].int!,
                                                   title: question["title"].string!,
                                                   body: question["body"].string!,
                                                   urgent: question["urgent"].int!,
                                                   elapsed: question["elapsed"].string!,
                                                   reward_coin: question["reward_coin"].int!,
                                                   user: User(id: question["user"]["id"].int!,
                                                              name: question["user"]["name"].string!
                                          )))
                }
                if json["questions"]["next_page_url"].string != nil {
                    self.nextUrl = json["questions"]["next_page_url"].string!
                }
                self.transitionToIndexView()
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }

    
}
