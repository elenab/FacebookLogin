//
//  ViewController.swift
//  LoginDemo
//
//  Created by Elena Busila on 2017-02-23.
//  Copyright © 2017 Elena Busila. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import SwiftyJSON
import Alamofire
import Kingfisher


class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var musicCollectionView: UICollectionView!
    @IBOutlet weak var loginView: UIVisualEffectView!
    @IBOutlet weak var fbLoginButton: UIButton!
    
    var youtubeApiKey = "AIzaSyDM6LWim6dhQfJHCuF310s6sgNO--h9O7o"
    
    struct playlistObject {
        var title: String
        var description: String
        var thumbnail: String
        
        init(json: JSON) {
            title = json["snippet"]["title"].stringValue
            description = json["snippet"]["description"].stringValue
            thumbnail = json["snippet"]["thumbnails"]["default"]["url"].stringValue
            print(title, description, thumbnail)
        }
    }
    
    var playlists : [playlistObject] = []
    var musicData = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        musicCollectionView.delegate = self
        musicCollectionView.dataSource = self
    }
    
    @IBAction func fbLoginButtonClicked(_ sender: UIButton) {
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "user_actions.music", "user_likes"], from: self, handler:{(result , error)-> Void in
            if (error == nil){
                let fbloginresult : FBSDKLoginManagerLoginResult = result!
                if fbloginresult.grantedPermissions != nil {
                    if(fbloginresult.grantedPermissions.contains("user_actions.music")) {
                        self.loginView.isHidden = true
                        self.getUserMusicData()
                    }
                }
            }
        })
    }
    
    func getUserMusicData(){
        if((FBSDKAccessToken.current()) != nil) {
            FBSDKGraphRequest(graphPath: "me/music", parameters: nil).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil) {
                    let json = JSON(result as Any)
                    if let items = json["data"].array {
                        for item in items {
                            self.musicData.append(item["name"].stringValue)
                        }
                    }
                    if (self.musicData.count > 0) {
                        self.getYoutubeDetails(musicData: self.musicData)
                    }
                }
            })
        }
    }

    func getYoutubeDetails(musicData:[String]) {
        for keyword in musicData {
            let newKeyword = keyword.replacingOccurrences(of: " ", with: "+")
            let urlString: String! = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=playlist&q=\(newKeyword)&maxResults=10&key=\(youtubeApiKey)"
            
            Alamofire.request(urlString).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if let items = json["items"].array {
                        for item in items {
                            let playlistObj = playlistObject(json: item)
                            self.playlists.append(playlistObj)
                        }
                        // Reload the collection.
                        self.musicCollectionView.reloadData()
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath)
            as! PlaylistCollectionViewCell
        
        cell.title.text = self.playlists[indexPath.item].title
        let url = URL(string: self.playlists[indexPath.item].thumbnail)
        cell.imageView.kf.setImage(with: url)
        cell.descriptionLabel.text =  self.playlists[indexPath.item].description
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

