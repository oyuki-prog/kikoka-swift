//
//  ShowViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess


class ShowViewController: UIViewController {
    let consts = Constants.shared
    var token = ""
    
    var showQuestion: ShowQuestion?
    var question: Question?
    var answers: [Answer] = []
    var sortedAnswers: [Answer] = []
    var answer: Answer?
    var myId: Int = 0
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var showTableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rewardLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var senderButton: UIButton!
    
    fileprivate var currentTextViewHeight: CGFloat = 38.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showTableView.delegate = self
        showTableView.dataSource = self
        senderButton.isEnabled = false
        getUserInfo()
        
        self.sortedAnswers = answers.sorted {$0.id < $1.id } .map { $0 }
        
        titleLabel.text = question!.title
        nameLabel.text = question!.user.name
        rewardLabel.text = String(question!.reward_coin)
        bodyLabel.text = question!.body
        
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        textView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
            }
        }
    }
    
    //キーボードが隠れたら画面の位置も元に戻す
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    //タップでキーボードを隠す
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let headerView = showTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + 50
            
            if height != headerView.frame.size.height {
                showTableView.tableHeaderView?.frame.size.height = height
            }
        }
    }
    
    @IBAction func pressBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressSendButton(_ sender: Any) {
        postAnswer()
    }
    
    func postAnswer() {
        let keychain = Keychain(service: self.consts.service)
        guard let token = keychain["access_token"] else {return}
        let url = URL(string: consts.baseUrl + "/questions/\(String(question!.id))/answers")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        let parameters: Parameters = [
            "body": textView.text!,
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.sortedAnswers.append(Answer(id: json["answer"]["id"].int!,
                                                 body: json["answer"]["body"].string!,
                                                 elapsed: json["answer"]["elapsed"].string!,
                                                 user: User(id: json["answer"]["user"]["id"].int!,
                                                            name: json["answer"]["user"]["name"].string!)))
                self.textView.text = ""
                self.senderButton.isEnabled = false
                self.showTableView.reloadData()
                
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    func getUserInfo() {
        let keychain = Keychain(service: self.consts.service)
        guard let token = keychain["access_token"] else {return}
        let url = URL(string: consts.baseUrl + "/user")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        AF.request(url, method: .get, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
                self.myId = json["id"].int!
                if self.myId == self.question!.user.id {
                    self.senderButton.isEnabled = false
                    self.textView.text = "自分の質問には回答できません"
                } else {
                    let answerd = self.sortedAnswers.filter({ $0.user.id == self.myId})
                    if answerd.count == 0 {
                        self.senderButton.isEnabled = true
                    } else {
                        self.textView.text = "回答済みの質問です"
                    }
                }
                
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}

extension ShowViewController: UITableViewDelegate,UITableViewDataSource {
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedAnswers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "showCell", for: indexPath)
        
        let bodyLabel = cell.viewWithTag(5) as! UILabel
        bodyLabel.text = sortedAnswers[indexPath.row].body
        
        let nameLabel = cell.viewWithTag(6) as! UILabel
        nameLabel.text = sortedAnswers[indexPath.row].user.name
        
        let elapsedLabel = cell.viewWithTag(7) as! UILabel
        elapsedLabel.text = sortedAnswers[indexPath.row].elapsed
        
        return cell
    }
}

extension ShowViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let contentHeight = self.textView.contentSize.height
        
        //@38.0: textViewの高さの最小値
        //@80.0: textViewの高さの最大値
        if 38.0 <= contentHeight && contentHeight <= 100.0 {
            
            self.textView.translatesAutoresizingMaskIntoConstraints = true
            self.textView.sizeToFit()
            self.textView.isScrollEnabled = false
            let resizedHeight = self.textView.frame.size.height
            self.textViewHeight.constant = resizedHeight
            //@x: 60（左のマージン）
            //@y: 10（上のマージン）
            //@width: self.view.frame.width - 120(左右のマージン)
            //@height: sizeToFit()後の高さ
            self.textView.frame = CGRect(x: 20, y: 20, width: self.view.frame.width - 70, height: resizedHeight)
            
            if resizedHeight > currentTextViewHeight {
                let addingHeight = resizedHeight - currentTextViewHeight
                self.textViewContainerHeight.constant += addingHeight
                currentTextViewHeight = resizedHeight
            } else if resizedHeight < currentTextViewHeight {
                let subtractingHeight = currentTextViewHeight - resizedHeight
                self.textViewContainerHeight.constant -= subtractingHeight
                currentTextViewHeight = resizedHeight
            }
            
        } else {
            self.textView.isScrollEnabled = true
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.myId == self.question!.user.id {
            senderButton.isEnabled = false
        }
    }
}
