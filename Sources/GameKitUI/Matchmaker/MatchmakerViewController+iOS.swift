///
/// MIT License
///
/// Copyright (c) 2020 Sascha Müllner
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///
/// Created by Sascha Müllner on 23.02.21.

import Foundation
import GameKit
import SwiftUI

public class MatchmakerViewController: UIViewController, GKMatchDelegate {
    
    private let matchRequest: GKMatchRequest
    private var matchmakingMode: Any? = nil
    private let canceled: () -> Void
    private let failed: (Error) -> Void
    private let started: (GKMatch) -> Void

    @available(iOS 14.0, *)
    public init(matchRequest: GKMatchRequest,
                matchmakingMode: GKMatchmakingMode,
                canceled: @escaping () -> Void,
                failed: @escaping (Error) -> Void,
                started: @escaping (GKMatch) -> Void) {
        self.matchRequest = matchRequest
        self.matchmakingMode = matchmakingMode
        self.canceled = canceled
        self.failed = failed
        self.started = started
        super.init(nibName: nil, bundle: nil)
    }

    public init(matchRequest: GKMatchRequest,
                canceled: @escaping () -> Void,
                failed: @escaping (Error) -> Void,
                started: @escaping (GKMatch) -> Void) {
        self.matchRequest = matchRequest
        self.canceled = canceled
        self.failed = failed
        self.started = started
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if GKLocalPlayer.local.isAuthenticated {
            self.showMatchmakerViewController()
        } else {
            self.showAuthenticationViewController()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        self.removeAll()
    }
    
    public func showAuthenticationViewController() {
        let authenticationViewController = GKAuthenticationViewController { (error) in
            self.failed(error)
        } authenticated: { (player) in
            self.showMatchmakerViewController()
        }
        self.add(authenticationViewController)
    }
    
    public func showMatchmakerViewController() {
        if let viewController = GKMatchmakerViewController(matchRequest: self.matchRequest) {
            viewController.matchmakerDelegate = self

            if #available(iOS 14, *) {
                viewController.matchmakingMode = self.matchmakingMode as? GKMatchmakingMode ?? .default
            }

            self.add(viewController)
        } else {
            self.canceled()
        }
    }
    
}

extension MatchmakerViewController: GKMatchmakerViewControllerDelegate {

    public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.started(match)
                viewController.remove()
        })
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        self.showMatchmakerViewController()
    }
    
    public func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.canceled()
                viewController.remove()
        })
    }
    
    public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.failed(error)
                viewController.remove()
        })
    }
}
