//
//  TILoadingViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxSwift

final class TILoadingViewController: UIViewController {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var subtitleLabel2: UILabel!

    private var animated = false
    private var nextViewController: UIViewController?
	private let path = "http://opml.radiotime.com/"

	// MARK: - View life cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setNavigationBarHidden(true, animated: false)

		let networkService =
			(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

        doFirstLoadingAnimation()

		// load data for next view
		fetchBrowseMenu(with: networkService, path: path)
	}

    func doFirstLoadingAnimation() {
        subtitleLabel.transform.ty += 50
        subtitleLabel2.transform.ty -= 50

        UIView.animateWithDuration(
            1.5,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 0,
            options: .CurveEaseOut,
            animations: {

            self.subtitleLabel.transform.ty -= 50
            self.subtitleLabel2.transform.ty += 50
        }) { complete in

            // if loading is finished, before animation is done.
            // do second animation here
            if let vc = self.nextViewController {
                self.doSecondLoadingAnimation {
                    (UIApplication.sharedApplication().delegate as! TIAppDelegate)
                        .window?.rootViewController = vc
                }
            }
            self.animated = true
        }
    }

    func doSecondLoadingAnimation(completion: () -> Void) {
        UIView.animateWithDuration(1.0, animations: {
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0

            self.titleLabel.transform.ty -= 300
            self.subtitleLabel.transform.ty -= 300
            self.subtitleLabel2.transform.ty += 300

            self.view.backgroundColor = UIColor.whiteColor()
        }, completion:  { finished in
            completion()
        })
    }

	// MARK: - Network Request - Move to viewModel if create one.
	func fetchBrowseMenu(with service: NetworkService, path: String) {

		service.simpleTIGetRequest(
			with: path
		) { [weak self] (result: Result<TIBrowse>) in

			switch result {
			case .success(let value):
				guard let tabBarController = UIStoryboard.mainStoryboard()
					.instantiateViewControllerWithIdentifier(
						TabBarControllerIdentifier.rootTabBar) as? UITabBarController,
					let navController = tabBarController.viewControllers?[0]
						as? UINavigationController,
					let topVc = navController.topViewController as? TIBrowseViewController else {

					// unrecoverable error
					fatalError("Could not instantiate proper view controller")
				}

				let newViewModel = TIBrowseViewModel(
					browseItem: value,
					title: Variable<String?>(value.title)
				)
				topVc.viewModel = newViewModel
                self?.nextViewController = tabBarController

                // if first animation is done, proceed and do second
                if self?.animated == true {
                    self?.doSecondLoadingAnimation {
                        (UIApplication.sharedApplication().delegate as! TIAppDelegate)
                            .window?.rootViewController = tabBarController
                    }
                }

			case .failure:
				// probably better to handle recoverable and non-recoverable error differently
				// providing retry option for recoverable error would
				let title = "Network Error".localizedString
				let message = "Sorry, we are having an issue. Please try again later.".localizedString
				let alert = UIAlertController.create(
					with: title,
					message: message,
					buttonTitle: "Retry".localizedString,
					buttonAction: {
						self?.fetchBrowseMenu(with: service, path: path)
					}
				)
				alert.show()
			}
		}
	}
}