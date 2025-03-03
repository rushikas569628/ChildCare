//
//  ChildProfileViewController.swift
//  ChildCareApp
//
//  Created by Benitha on 18/02/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SVProgressHUD

class ChildProfileViewController: UIViewController {

    @IBOutlet weak var emailLBL: UILabel!
    @IBOutlet weak var nameLBL: UILabel!
    
    var user_id = ""
    var user_name = ""
    var parentID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "Profile"
        
        nameLBL.text = Auth.auth().currentUser?.displayName ?? ""
        emailLBL.text = Auth.auth().currentUser?.email ?? ""
    }
    
    
    func getParrentData() -> Void {
        
        let database = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""
        
        let docRef = database.collection("Childs")
            .whereField("id", isEqualTo: id)
        
        SVProgressHUD.show()
        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                
                SVProgressHUD.dismiss()
                print("Error getting documents: \(err)")
                
            }else {
                   
                SVProgressHUD.dismiss()
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    let data = document.data()
                    
                    self.user_id = data["parent_id"] as? String ?? ""
                    self.user_name = data["parent_name"] as? String ?? ""
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.getParrentData()
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "chat" {
            
            let vc = segue.destination as! ChatViewController
            vc.user_ID = self.user_id
            vc.user_name = self.user_name
        }
    }
    
    
    
    @IBAction func chat(_ sender: Any) {
        
        self.performSegue(withIdentifier: "chat", sender: self)
    }
    
    func getChildData() -> Void {
        
        let database = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""
        
        SVProgressHUD.show()
        let docRef = database.collection("Childs")
            .whereField("id", isEqualTo: id)
        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                
                SVProgressHUD.dismiss()
                print("Error getting documents: \(err)")
                
            } else {
                
                if querySnapshot?.documents.count ?? 0 > 0 {
                    
                    let document = querySnapshot!.documents[0]
                    
                    let data = document.data()
                    self.parentID = data["parent_id"] as? String ?? ""
                    
                    self.sendNotification()
                }
            }
        }
    }
    
    func sendNotification() -> Void {
        
        let path = String(format: "%@", "Notifications")
        let db = Firestore.firestore()
        
        let id = Auth.auth().currentUser?.uid ?? ""
        let name = Auth.auth().currentUser?.displayName ?? ""
        
        let myTimeStamp = Date().timeIntervalSince1970
        
        let notifData: [String: Any] = [
            "child_name": name,
            "parent_id": self.parentID,
            "child_id": id,
            "type": 2,
            "timestamp": myTimeStamp
        ]
        
        db.collection(path).document().setData(notifData) { err in
            if let _ = err {
                
                SVProgressHUD.dismiss()
                
            }else {
                
                self.logoutChild()
            }
        }
    }
    
    
    @IBAction func logout(_ sender: Any) {
        
        self.getChildData()
    }
    
    func logoutChild() -> Void {
        
        
        SVProgressHUD.dismiss()
        do {
            
            try Auth.auth().signOut()
        } catch {}
        
        let vc = self.storyboard?.instantiateViewController(identifier: "SplashViewController") as! SplashViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
}
