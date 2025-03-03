//
//  ChildDetailViewController.swift
//  ChildCareApp
//
//  Created by Benitha on 04/02/2025.
//

import UIKit

class ChildDetailViewController: UIViewController {

    @IBOutlet weak var profileIV: UIImageView!
    @IBOutlet weak var nameLBL: UILabel!
    @IBOutlet weak var deviceLBL: UILabel!
    @IBOutlet weak var addressLBL: UILabel!
    
    var childData: ChildModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController?.tabBar.isHidden = true
        // Do any additional setup after loading the view.
        setData()
    }
    
    func setData() -> Void {
        
        nameLBL.text = childData?.name ?? ""
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "chat" {
            
            let vc = segue.destination as! ChatViewController
            vc.user_ID = childData?.id ?? ""
            vc.user_name = childData?.name ?? ""
        }else if segue.identifier == "restricted_location" {
            
            let vc = segue.destination as! RestrictedAreasViewController
            vc.childData = childData
        }
        
    }
    
    
    
    @IBAction func chat(_ sender: Any) {
        
        self.performSegue(withIdentifier: "chat", sender: self)
    }
    
    @IBAction func addLocation(_ sender: Any) {
        
        self.performSegue(withIdentifier: "restricted_location", sender: self)
    }
    
    @IBAction func viewLocation(_ sender: Any) {
        
        
    }
}
