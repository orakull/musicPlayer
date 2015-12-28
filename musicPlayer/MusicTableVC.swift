//
//  MusicTableVC.swift
//  musicPlayer
//
//  Created by Руслан Ольховка on 26.12.15.
//  Copyright © 2015 Руслан Ольховка. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol SongDelegate {
	optional func imageLoaded(song: Song)
}
class Song: NSObject {
	
	var artist: String
	var title: String
	var picUrl: String
	var demoUrl: String
	var image: UIImage? {
		didSet {
			delegate?.imageLoaded?(self)
		}
	}
	
	var delegate: SongDelegate?
	
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
	static let songCellIdentifier = "songCell"
	static let loadingCellIdentifier = "loadingCell"
	static let noImage = UIImage(named: "noAlbumArt")!
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
    }
	
	// MARK: - Getting data
	
	func getSongs() {
		DownloadUtil.downloadUrl(preparedURL) { (data) -> Void in
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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return songs.count + (loadedAll ? 0 : 1)
    }
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if !loadedAll && indexPath.row == songs.count - 1 {
			getSongs()
		}
	}

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if (indexPath.row < songs.count) {
			let cell = tableView.dequeueReusableCellWithIdentifier(Constants.songCellIdentifier, forIndexPath: indexPath)
			let song = songs[indexPath.row]
			cell.textLabel?.text = song.title
			cell.detailTextLabel?.text = song.artist
			if let image = song.image {
				cell.imageView?.image = image
			} else {
				cell.imageView?.image = Constants.noImage
				DownloadUtil.downloadUrl(song.picUrl, completionBlock: { (data) -> Void in
					dispatch_async(dispatch_get_main_queue()) { () -> Void in
						if let data = data {
							let image = UIImage(data: data)
							cell.imageView?.image = image
							song.image = image
						}
					}
				})
			}
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier(Constants.loadingCellIdentifier, forIndexPath: indexPath)
			return cell
		}
		
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

    // MARK: - Navigation

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

// MARK: -

class DownloadUtil {
	static func downloadUrl(url:String, completionBlock: (NSData?) -> Void) {
		let request = NSMutableURLRequest(URL: NSURL(string: url)!,
			cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
			timeoutInterval: 15.0)
		let queue = NSOperationQueue()
		NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
			completionBlock(data)
		}

	}
}
