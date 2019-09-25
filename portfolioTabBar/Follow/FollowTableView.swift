//
//  FollowTableView.swift
//  portfolioTabBar
//
//  Created by Loho on 20/08/2019.
//  Copyright © 2019 Loho. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class FollowTableView: UITableViewController {
    
    var users = [User]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.users.removeAll()
        self.fetchFollowingUser()
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let selectedMentorView = homeStoryboard.instantiateViewController(withIdentifier: "selectedMentorView") as! SelectedMentorView
        selectedMentorView.followTableView = self
//        
//        self.users.removeAll()
//        self.fetchFollowingUser()
//        self.tableView.reloadData()
    }
    
    func fetchFollowingUser() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        tableView?.refreshControl?.beginRefreshing()
        
        Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            
            userIdsDictionary.forEach({ (uid, value) in
                Database.database().fetchUser(withUID: uid, completion: {(user) in
                    self.users.append(user)
                    self.users.sort(by: { (user1, user2) -> Bool in
                        return user1.username!.compare(user2.username!) == .orderedDescending
                    })
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                })
            })
        }) { (err) in
            self.tableView?.refreshControl?.endRefreshing()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let selectedMentorView = homeStoryboard.instantiateViewController(withIdentifier: "selectedMentorView") as? SelectedMentorView
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.user = users[indexPath.row]
        selectedMentorView!.user = users[indexPath.row]
        self.navigationController?.pushViewController(selectedMentorView!, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //MessageAction
        let messageAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            success(true)
            let messageLogController = MessageLogController(collectionViewLayout: UICollectionViewFlowLayout())
            messageLogController.selectedFollowUser = self.users[indexPath.item]
            messageLogController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(messageLogController, animated: true)
        })
        messageAction.image = UIImage(named: "message.png")
        messageAction.backgroundColor = UIColor.colorWithRGBHex(hex: 0x60C3FF)
        //MatchingAction
        let matchingAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            success(true)

            let contractStoryboard = UIStoryboard(name: "Contract", bundle: nil)
            let requestViewController = contractStoryboard.instantiateViewController(withIdentifier: "requestController") as! SendRequestController
            requestViewController.selectedUser = self.users[indexPath.row]
            requestViewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(requestViewController, animated: true)
        })
        
        matchingAction.image = UIImage(named: "request.png")
        matchingAction.backgroundColor = UIColor.colorWithRGBHex(hex: 0x5887F9)
        //UnfollowingAction
        let unfollowAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            success(true)
            let alertController = UIAlertController(title: "UnFollow", message:
                "Do you want to unfollow it?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: {action in
                let userId = self.users[indexPath.item].uid
                Database.database().isFollowingUser(withUID: userId, completion: { (following) in
                    if following {
                        Database.database().unfollowUser(withUID: userId) { (err) in
                            if err != nil {
                                return
                            } else {
                                DispatchQueue.main.async(execute: {
                                    self.users.removeAll()
                                    self.fetchFollowingUser()
                                    self.tableView.reloadData()
                                })
                            }
                        }
                    }
                }) { (err) in
                    //
                }
            }))
            alertController.addAction(UIAlertAction(title: "Cancle", style: .default, handler: {action in
            }))
            self.present(alertController, animated: true, completion: nil)
        })
        
        unfollowAction.image = UIImage(named: "unfollowing.png")
        unfollowAction.backgroundColor = UIColor.red
        
        return UISwipeActionsConfiguration(actions:[unfollowAction,matchingAction,messageAction])

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FollowTableCell.followCellID, for: indexPath) as! FollowTableCell
        
        cell.user = users[indexPath.item]
        cell.followUserImageView.layer.cornerRadius = 5
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
