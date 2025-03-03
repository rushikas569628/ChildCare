//
//  HomeViewController.swift
//  ChildCareApp
//
//  Created by Benitha on 03/02/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SVProgressHUD

class HomeViewController: UIViewController {

    @IBOutlet weak var childsCV: UICollectionView!
    
    var allChildsList: [ChildModel] = []
    var selectedChild: ChildModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        childsCV.backgroundColor = .clear
        navigationItem.hidesBackButton = true
        navigationItem.title = "Home"
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        self.getMyChilds()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "childDetail" {
            
            let vc = segue.destination as! ChildDetailViewController
            vc.childData = self.selectedChild
        }
        
    }
    

    func getMyChilds() -> Void {
        
        let database = Firestore.firestore()
        let id = Auth.auth().currentUser?.uid ?? ""
        
        let docRef = database.collection("Childs")
            .whereField("parent_id", isEqualTo: id)
        docRef.addSnapshotListener { (querySnapshot, err) in
            if let err = err {
                
                print("Error getting documents: \(err)")
                
            } else {
                
                self.allChildsList.removeAll()
                
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    let data = document.data()
                    
                    var child = ChildModel()
                    child.id = data["id"] as? String ?? ""
                    child.parent_id = data["parent_id"] as? String ?? ""
                    child.parent_name = data["parent_name"] as? String ?? ""
                    child.name = data["name"] as? String ?? ""
                    child.age = data["age"] as? String ?? ""
                    child.email = data["email"] as? String ?? ""
                    child.image = data["image"] as? String ?? ""
                    child.lat = data["lat"] as? Double ?? 0.0
                    child.lng = data["lng"] as? Double ?? 0.0
                    child.address = data["address"] as? String ?? ""
                    
                    self.allChildsList.append(child)
                }
                
                self.childsCV.reloadData()
            }
        }
    }
}


extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.allChildsList.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var width = 0.0
        let view = self.view.frame.size.width - 34
        
        width = Double(view / 2)
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell : ChildCVC = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChildCVC
        cell.backgroundColor = .clear
        
        if indexPath.item == self.allChildsList.count {
            
            cell.imgView.image = UIImage(systemName: "plus.circle")
            cell.txtLbl.text = "Add Child"
        }else {
            
            let childData = self.allChildsList[indexPath.item]
                
            cell.imgView.image = UIImage(systemName: "person.circle")
            cell.txtLbl.text = childData.name
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.item == self.allChildsList.count {
            
            self.performSegue(withIdentifier: "addChild", sender: nil)
        }else {
            
            selectedChild = allChildsList[indexPath.item]
            self.performSegue(withIdentifier: "childDetail", sender: nil)
        }
    }
}
