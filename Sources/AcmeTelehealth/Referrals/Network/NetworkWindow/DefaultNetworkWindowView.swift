import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default network window.
    final class DefaultNetworkWindowView {
        var code: String
        var label: String
        var ownerIDText: String
        var contactEmail: String
        var activeText: String
        var revisionText: String
        var discount: String
        var retries: String
        var title: String
        var statusLabel: String

        init(code: String, label: String, ownerIDText: String, contactEmail: String, activeText: String, revisionText: String, discount: String, retries: String, title: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerIDText = ownerIDText
            self.contactEmail = contactEmail
            self.activeText = activeText
            self.revisionText = revisionText
            self.discount = discount
            self.retries = retries
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultNetworkWindowView(_ item: DefaultNetworkWindow) -> DefaultNetworkWindowView {
        return DefaultNetworkWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            ownerIDText: item.ownerID,
            contactEmail: item.contactEmail,
            activeText: "\(item.active)",
            revisionText: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            retries: String(item.retries),
            title: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultNetworkWindowViews(_ items: [DefaultNetworkWindow]) -> [DefaultNetworkWindowView] {
        var views: [DefaultNetworkWindowView] = []
        for item in items {
            views.append(toDefaultNetworkWindowView(item))
        }
        return views
    }

    static func sumDefaultNetworkWindowView(_ view: DefaultNetworkWindowView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + Double(parsedRetries)
    }
}
