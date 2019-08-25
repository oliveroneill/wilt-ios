import Foundation

extension String {
    /// Get the localized string using self as the id
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
