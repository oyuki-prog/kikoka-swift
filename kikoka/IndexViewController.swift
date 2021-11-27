//
//  IndexViewController.swift
//  kikoka
//
//  Created by o.yuki on 2021/11/27.
//

import UIKit
import Alamofire
import SwiftyJSON
import KeychainAccess


class IndexViewController: UIViewController {
    let consts = Constants.shared
    var token = ""
    var questions: [Question] = []
    var answers: [Answer] = []
    var sortedQuestions: [Question] = []
    var question: Question?
    
    @IBOutlet weak var questionTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sortedQuestions = questions.sorted {$0.reward_coin > $1.reward_coin } .map { $0 }
        
        questionTableView.delegate = self
        questionTableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    func getShow(questionId: Int) {
        let url = URL(string: consts.baseUrl + "/questions/\(questionId)")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "ACCEPT": "application/json",
        ]
        
        AF.request(url, method: .get, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                self.answers = []
                let json = JSON(value)
                for answer in json["question"][0]["answers"].arrayValue {
                    self.answers.append(Answer(id: answer["id"].int!,
                                               body: answer["body"].string!,
                                               elapsed: answer["elapsed"].string!,
                                               user: User(id: answer["user"]["id"].int!,
                                                          name: answer["user"]["name"].string!
                                              )))
                }
                let question = json["question"][0]
                self.question = Question(id: question["id"].int!,
                                         title: question["title"].string!,
                                         body: question["body"].string!,
                                         urgent: question["urgent"].int!,
                                         elapsed: question["elapsed"].string!,
                                         reward_coin: question["reward_coin"].int!,
                                         user: User(id: question["user"]["id"].int!,
                                                    name: question["user"]["name"].string!
                                                   ))
                let showVC = self.storyboard?.instantiateViewController(withIdentifier: "showVC") as! ShowViewController
                showVC.question = self.question
                showVC.answers = self.answers
                self.present(showVC, animated: true, completion: nil)
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    
    
}

extension IndexViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedQuestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "questionCell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        titleLabel.text = sortedQuestions[indexPath.row].title
        
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = sortedQuestions[indexPath.row].user.name
        
        let rewardLabel = cell.viewWithTag(3) as! UILabel
        rewardLabel.text = String(sortedQuestions[indexPath.row].reward_coin)
        
        return cell
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        let indexPath = self.questionTableView.indexPathForSelectedRow
    //        getShow(questionId: sortedQuestions[indexPath!.row].id)
    //        if segue.identifier == "showSegue" {
    //            let showVC: ShowViewController = (segue.destination as? ShowViewController)!
    //            showVC.showQuestion = self.showQuestion
    //        }
    //    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        getShow(questionId: sortedQuestions[indexPath.row].id)
        questionTableView.deselectRow(at: indexPath, animated: true)
    }
}
