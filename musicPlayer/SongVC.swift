//
//  SongVC.swift
//  musicPlayer
//
//  Created by Руслан Ольховка on 26.12.15.
//  Copyright © 2015 Руслан Ольховка. All rights reserved.
//

import UIKit

class SongVC: UIViewController, SongDelegate {

	var song: Song? {
		didSet {
			imageView?.image = song?.image ?? Constants.noImage
			title = song?.title
			song?.delegate = self
		}
	}
	
	@IBOutlet weak var imageView: UIImageView! {
		didSet {
			imageView.image = song?.image ?? Constants.noImage
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func imageLoaded(song: Song) {
		imageView.image = song.image
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
