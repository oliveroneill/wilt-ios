/// Add an extension to display a loading spinner in place of the search icon.
/// There's a lot of hacky stuff in here, but I think it looks pretty good
extension UISearchBar {
    private var textField: UITextField? {
        if #available(iOS 13.0, *) {
            return searchTextField
        } else {
            // Search for the text field in older versions of iOS
            let subViews = subviews.flatMap { $0.subviews }
            return (subViews.filter { $0 is UITextField }).first as? UITextField
        }
    }

    /// Will be set to the activity indicator if it's visible on the search bar
    private var activityIndicator: UIActivityIndicatorView? {
        textField?.leftView?.subviews.compactMap {
            $0 as? UIActivityIndicatorView
        }.first
    }

    private var searchIcon: UIImage? {
        let subViews = subviews.flatMap { $0.subviews }
        return ((subViews.filter { $0 is UIImageView }).first as? UIImageView)?.image
    }

    /// This will enable or disable the loading spinner
    var isLoading: Bool {
        get {
            activityIndicator != nil
        } set {
            guard newValue else {
                activityIndicator?.removeFromSuperview()
                return
            }
            guard activityIndicator == nil else { return }
            // Place an activity indicator on the search bar
            let newActivityIndicator = UIActivityIndicatorView(style: .gray)
            newActivityIndicator.startAnimating()
            if #available(iOS 13.0, *) {
                // This is the closest I could get to the background colour,
                // this will probably break in the next iOS release :(
                newActivityIndicator.backgroundColor = UIColor(
                    red: 0.9,
                    green: 0.9,
                    blue: 0.9,
                    alpha: 1
                )
            } else {
                newActivityIndicator.backgroundColor = .groupTableViewBackground
            }
            newActivityIndicator.transform = CGAffineTransform(
                scaleX: 0.9, y: 0.9
            )
            textField?.leftView?.addSubview(newActivityIndicator)
            // Position the spinner
            let leftViewSize = textField?.leftView?.frame.size ?? .zero
            newActivityIndicator.center = CGPoint(
                x: leftViewSize.width / 2,
                y: leftViewSize.height / 2
            )
        }
    }
}
