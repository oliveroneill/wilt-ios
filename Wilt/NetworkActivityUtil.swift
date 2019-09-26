/// Utility for hiding and displaying the activity indicator
enum NetworkActivityUtil {
    static func showNetworkIndicator() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }

    static func hideNetworkIndicator() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
