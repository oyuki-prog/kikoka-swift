//
//  LoginViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess

class LoginViewController: UIViewController {
    let consts = Constants.shared
    var token = ""
    
    var questions: [Question] = []
    
    var emailText: String?
    var passwordText: String?
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var caution: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        loginButton.isEnabled = false
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func pressLoginButton(_ sender: Any) {
        self.getAccessToken()
//        self.getIndex()
    }
    
    func getAccessToken() {
        let url = URL(string: consts.baseUrl + "/login")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json"
        ]
        let parameters: Parameters = [
            "email": emailField.text!,
            "password": passwordField.text!
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if json["errors"] == "User Not Found." {
                    self.caution.text = json["errors"].string!
                    return
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
        indexNC.modalPresentationStyle = .fullScreen
        present(indexNC, animated: true, completion: nil)
    }
    
    @IBAction func emailFieldChanged(_ sender: UITextField) {
        emailText = sender.text
        self.validate()
    }
    
    @IBAction func passwordFieldChanged(_ sender: UITextField) {
        passwordText = sender.text
        self.validate()
    }
    
    private func validate() {
        guard let email = self.emailText,
              let password = self.passwordText else {
                  self.loginButton.isEnabled = false
                  return
              }
        
        if email.count == 0 || password.count == 0 {
            self.loginButton.isEnabled = false
            return
        }
        
        self.loginButton.isEnabled = true
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
                self.transitionToIndexView()
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}
