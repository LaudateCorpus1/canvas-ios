//
// Copyright (C) 2019-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

/// To successfully avoid the keyboard, you need to animate a constraint in sync with the keyboard.
/// Initialize a `KeyboardTransitioning` in `viewDidAppear` and save it as a property.
public class KeyboardTransitioning {
    weak var view: UIView?
    weak var space: NSLayoutConstraint?
    var callback: (() -> Void)?

    public init(view: UIView?, space: NSLayoutConstraint?, callback: (() -> Void)? = nil) {
        self.view = view
        self.space = space
        self.callback = callback

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let view = view, let space = space,
            let info = notification.userInfo as? [String: Any],
            let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let constant = max(0, view.bounds.height - view.safeAreaInsets.bottom - view.convert(keyboardFrame, from: nil).origin.y)
        guard
            let animationCurve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let animationDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else {
            space.constant = constant
            view.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: animationDuration, delay: 0, options: .init(rawValue: animationCurve), animations: {
            space.constant = constant
            view.layoutIfNeeded()
        }, completion: nil)
    }
}
