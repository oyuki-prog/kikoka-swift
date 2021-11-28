//
//  FirstViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess


class FirstViewController: UIViewController {
    let consts = Constants.shared
    var questions: [Question] = []
    var nextUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let keychain = Keychain(service: self.consts.service)
        //        print(keychain["access_token"])
        keychain["access_token"] = nil //ログインの挙動を確かめたいときはこの行を有効にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if keychain["access_token"] == nil {
                let authVC = self.storyboard?.instantiateViewController(withIdentifier: "authVC") as! UIViewController
                authVC.modalPresentationStyle = .fullScreen
                self.present(authVC, animated: true, completion: nil)
            } else {
                self.getIndex()
            }
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
                print(json["questions"]["next_page_url"].string)
                if json["questions"]["next_page_url"].string != nil {
                    self.nextUrl = json["questions"]["next_page_url"].string!
                }
                self.transitionToIndexView()
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
        indexVC.nextUrl = self.nextUrl
        present(indexNC, animated: true, completion: nil)
    }

}
