import Foundation

extension String {
    /// Get the localized string using self as the id
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension UITableViewCell {
    /// Nudge the table view cell to indicate that there is a swipe action available
    ///
    /// - Parameters:
    ///   - swipeActionColor: The color of the underlying action
    func hintSwipeAction(swipeActionColor: UIColor) {
        let swipeView = UILabel(
            frame: CGRect(
                x: bounds.size.width,
                y: 0,
                width: bounds.size.width,
                height: bounds.size.height
            )
        )
        swipeView.backgroundColor = swipeActionColor
        addSubview(swipeView)
        // Animate the view moving over 10 points and then moving back
        let nudgeWidth: CGFloat = 10
        let nudgeDuration = 0.3
        let originalX = frame.origin.x
        UIView.animate(withDuration: nudgeDuration, animations: {
            self.frame = CGRect(
                x: originalX - nudgeWidth,
                y: self.frame.origin.y,
                width: self.bounds.size.width,
                height: self.bounds.size.height
            )
        }) { _ in
            UIView.animate(withDuration: nudgeDuration, animations: {
                self.frame = CGRect(
                    x: originalX,
                    y: self.frame.origin.y,
                    width: self.bounds.size.width,
                    height: self.bounds.size.height
                )
            }) { _ in
                swipeView.removeFromSuperview()
            }
        }
    }
}
