//
//  MusicTableVC.swift
//  musicPlayer
//
//  Created by Руслан Ольховка on 26.12.15.
//  Copyright © 2015 Руслан Ольховка. All rights reserved.
//

import UIKit

class Song {
	var artist: String
	var title: String
	var picUrl: String
	var demoUrl: String
	var image: UIImage?
	init(artist: String, title: String, picUrl: String, demoUrl: String) {
		self.artist = artist
		self.title = title
		self.picUrl = picUrl
		self.demoUrl = demoUrl
	}
}

struct Constants {
	static let apiURL = "https://api-content-beeline.intech-global.com/public/marketplaces/1/tags/10/melodies"
	static let songLimit = 10
	static let cellIdentifier = "songCell"
	static let noAlbumArt = "noAlbumArt"
}

class MusicTableVC: UITableViewController {
	
	var loaded = 0
	var loadedAll = false
	var preparedURL: String {
		return Constants.apiURL.stringByAppendingString("?limit=\(Constants.songLimit)&from=\(loaded)")
	}
	var songs = [Song]()
	
	@IBAction func refresh(sender: AnyObject) {
		loaded = 0
		loadedAll = false
		songs.removeAll()
		tableView.reloadData()
		getSongs()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		getSongs()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Getting data
	
	func getSongs() {
		let url = NSURL(string: preparedURL)
		let request = NSMutableURLRequest(URL: url!,
			cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
			timeoutInterval: 15.0)
		let queue = NSOperationQueue()
		NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
			if let data = data {
				let json = JSON(data: data)
				self.extractJSON(json)
			}
		}
	}
	
	func extractJSON(json: JSON) {
		let melodies = json["melodies"]
		if melodies.count < Constants.songLimit {
			self.loadedAll = true
		}
		self.loaded += melodies.count
		for i in 0..<melodies.count {
			let melody = melodies[i]
			let artist = melody["artist"].stringValue
			let title = melody["title"].stringValue
			let picUrl = melody["picUrl"].stringValue
			let demoUrl = melody["demoUrl"].stringValue
			let song = Song(artist: artist, title: title, picUrl: picUrl, demoUrl: demoUrl)
			songs.append(song)
		}
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.tableView.reloadData()
		}
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
		return songs.count + (loadedAll ? 0 : 1)
    }
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if !loadedAll && indexPath.row == songs.count - 1 {
			getSongs()
		}
	}

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.cellIdentifier, forIndexPath: indexPath)

		if (indexPath.row < songs.count) {
			let song = songs[indexPath.row]
			cell.textLabel?.text = song.title
			cell.detailTextLabel?.text = song.artist
			if let image = song.image {
				cell.imageView?.image = image
			} else {
				cell.imageView?.image = UIImage(named: Constants.noAlbumArt)
				downloadImageWithURL(url: song.picUrl, completionBlock: { (image: UIImage?) -> Void in
					dispatch_async(dispatch_get_main_queue()) { () -> Void in
						cell.imageView?.image = image
						song.image = image
					}
				})
			}
		} else {
			cell.textLabel?.text = "loading..."
			cell.detailTextLabel?.text = "please, be patient"
			cell.imageView?.image = UIImage(named: Constants.noAlbumArt)
		}
		
        return cell
    }
	
	func downloadImageWithURL(url imgUrl: String, completionBlock: (UIImage?) -> Void) {
		let url = NSURL(string: imgUrl)
		let request = NSMutableURLRequest(URL: url!,
			cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
			timeoutInterval: 15.0)
		let queue = NSOperationQueue()
		NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
			if let data = data {
				let image = UIImage(data: data)
				completionBlock(image)
			} else {
				completionBlock(nil)
			}
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let songVC = segue.destinationViewController as? SongVC {
			if let cell = sender as? UITableViewCell {
				let indexPath = tableView.indexPathForCell(cell)!
				let song = songs[indexPath.row]
				songVC.song = song
			}
		}
    }

}
