//
//  ChatViewController.swift
//  ChildCareApp
//
//  Created by Benitha on 30/01/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVKit
import SVProgressHUD

class ChatViewController: UIViewController {
    
    @IBOutlet weak var chatTV: UITableView!
    @IBOutlet var msgView: UIView!
    @IBOutlet weak var msgTF: UITextField!
    
    @IBOutlet weak var sendBtn: UIButton!
    
    var user_ID = ""
    var user_name = ""
    var allChat: [ChatModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController?.tabBar.isHidden = true
        self.navigationItem.title = "Chat"
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
        // Do any additional setup after loading the view.
        
        self.chatTV.delegate = self
        self.chatTV.dataSource = self
        
        //sendBtn.isEnabled = false
        
        self.getAllChat()
    }
    

    func getAllChat() -> Void {
                
        let id = Auth.auth().currentUser?.uid ?? ""
        
        let db = Firestore.firestore()
        let docRef = db.collection("Chats")
            .whereField("sender_id", in: [id, user_ID])
            .whereField("receiver_id", in: [id, user_ID])
        
        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
                
            } else {
                
                self.allChat.removeAll()
                SVProgressHUD.dismiss()
                
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    let data = document.data()
                    
                    let t = data["timestamp"] as? Double ?? 0.0
                    let date = Date(timeIntervalSince1970: t)
                    
                    var chat = Chat()
                    chat.id = document.documentID
                    chat.message = data["message"] as? String ?? ""
                    chat.sender_id = data["sender_id"] as? String ?? ""
                    chat.reveiver_id = data["reveiver_id"] as? String ?? ""
                    
                    
                    let f = DateFormatter()
                    f.dateFormat = "HH:mm:ss"
                    
                    chat.date = f.string(from: date)
                    
                    f.dateFormat = "dd/MM/yyyy"
                    let date_str = f.string(from: date)
                    
                    if let existingSectionIndex = self.allChat.firstIndex(where: { $0.date == date_str }) {
                        self.allChat[existingSectionIndex].chats?.append(chat)
                    } else {
                        var newSection = ChatModel()
                        newSection.date = date_str
                        newSection.chats = [chat]
                        self.allChat.append(newSection)
                    }
                    
                    self.allChat.sort { $0.date! < $1.date! }
                    self.chatTV.reloadData()
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func showAlert(str: String) -> Void {
        
        let alert = UIAlertController(title: "", message: str, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func sendBtn(_ sender: Any) {
        
        if msgTF.text == "" {
            
            self.showAlert(str: "Please enter message")
            return
        }
        
        let myTimeStamp = Date().timeIntervalSince1970
        
        let id = Auth.auth().currentUser?.uid ?? ""
        let name = Auth.auth().currentUser?.displayName ?? ""
        
        let params = ["message": msgTF.text!,
                      "sender_id": id,
                      "sender_name": name,
                      "receiver_id": user_ID,
                      "receiver_name": user_name,
                      "timestamp": myTimeStamp] as [String : Any]
        
        
        let path = String(format: "Chats")
        let db = Firestore.firestore()
        
        SVProgressHUD.show()
        db.collection(path).document().setData(params) { err in
            if let _ = err {
                
                SVProgressHUD.dismiss()
                self.showAlert(str: "Message sending failed")
            } else {
                
                SVProgressHUD.dismiss()
                self.msgTF.text = ""
            }
        }
    }
}


extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return allChat.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cell: HeaderCell! = tableView.dequeueReusableCell(withIdentifier: "headerCell") as? HeaderCell
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let date_str = allChat[section].date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let today = Date()
        let today_str = dateFormatter.string(from: today)
        
        let yesterday = today.addingTimeInterval(-1 * 24 * 60 * 60)
        let yesterday_str = dateFormatter.string(from: yesterday)
        
        if date_str == today_str {
            
            cell.dateLBL.text = "Today"
        }else if date_str == yesterday_str {
            
            cell.dateLBL.text = "Yesterday"
        }else {
            
            cell.dateLBL.text = date_str
        }
        
        return cell.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 44
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let chats = allChat[section].chats ?? []
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var chats = allChat[indexPath.section].chats ?? []
        chats.sort { $0.date! < $1.date! }
        let chat = chats[indexPath.row]
        
        let id = Auth.auth().currentUser?.uid ?? ""
        if chat.sender_id == id {
            
            let cell: SenderCell! = tableView.dequeueReusableCell(withIdentifier: "senderCell") as? SenderCell
            
            cell.chat = chat
            return cell
        }else{
            
            let cell: ReceiverCell! = tableView.dequeueReusableCell(withIdentifier: "receiverCell") as? ReceiverCell
            
            cell.chat = chat
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
}
