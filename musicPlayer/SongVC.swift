//
//  SongVC.swift
//  musicPlayer
//
//  Created by Руслан Ольховка on 26.12.15.
//  Copyright © 2015 Руслан Ольховка. All rights reserved.
//

import UIKit
import AVFoundation

class SongVC: UIViewController, SongDelegate {

	var player: AVPlayer!
	var playerItem: AVPlayerItem! {
		didSet {
			player = AVPlayer(playerItem: playerItem)
			
			updater = CADisplayLink(target: self, selector: Selector("trackAudio"))
			updater.frameInterval = 1
			updater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
		}
	}
	var updater: CADisplayLink!
	
	var song: Song! {
		didSet {
			imageView?.image = song.image ?? Constants.noImage
			title = song.title
			song.delegate = self
			playerItem = AVPlayerItem(URL: NSURL(string: song.demoUrl)!)
			playerItem.addObserver(self, forKeyPath: "status", options: .Initial, context: nil)
			player.addObserver(self, forKeyPath: "rate", options: .New, context: nil)
		}
	}
	
	// MARK: Outlets
	
	@IBOutlet weak var imageView: UIImageView! {
		didSet {
			imageView.image = song?.image ?? Constants.noImage
		}
	}
	@IBOutlet weak var progressSlider: UISlider!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var positionLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	
	// MARK: Actions
	
	@IBAction func playPause() {
		if playPauseButton.selected {
			player.pause()
		} else {
			player.play()
		}
	}
	
	@IBAction func sliderTouchUpInside(sender: AnyObject) {
		let seconds = playerItem.duration.seconds * Double(progressSlider.value)
		let time = CMTime(seconds: seconds, preferredTimescale: playerItem.duration.timescale)
		player.seekToTime(time)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidDisappear(animated: Bool) {
		playerItem.removeObserver(self, forKeyPath: "status")
		player.removeObserver(self, forKeyPath: "rate")
		updater.invalidate()
		player = nil
	}
	
	func trackAudio() {
		if progressSlider.highlighted {
			positionLabel.text = (Double(progressSlider.value) * playerItem.duration.seconds).stringTime
		} else {
			progressSlider.value = Float(player.currentTime().seconds / playerItem.duration.seconds)
			positionLabel.text = player.currentTime().seconds.stringTime
		}
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		switch keyPath! {
		case "status":
			if (playerItem.status == .ReadyToPlay) {
				durationLabel.text = playerItem.duration.seconds.stringTime
			}
		case "rate":
			playPauseButton.selected = player.rate == 1.0
			if player.currentTime().seconds == playerItem.duration.seconds {
				player.seekToTime(CMTime(seconds: 0, preferredTimescale: playerItem.duration.timescale))
			}
		default: break
		}
	}
	
	// MARK: - Song delegate
	
	func imageLoaded(song: Song) {
		imageView.image = song.image
	}
}

extension Double {
	var stringTime: String {
		let sec = self.isNaN ? 0 : Int(self)
		return String(format: "%02i:%02i", arguments: [sec / 60, sec % 60])
	}
}