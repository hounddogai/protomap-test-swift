import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling language tier.
    final class RollingLanguageTierView {
        var code: String
        var title: String
        var contactEmailText: String
        var retries: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, contactEmailText: String, retries: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmailText = contactEmailText
            self.retries = retries
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toRollingLanguageTierView(_ item: RollingLanguageTier) -> RollingLanguageTierView {
        return RollingLanguageTierView(
            code: item.code,
            title: item.title,
            contactEmailText: item.contactEmail,
            retries: String(item.retries),
            source: Kit.Text.truncate(item.source, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingLanguageTierViews(_ items: [RollingLanguageTier]) -> [RollingLanguageTierView] {
        var views: [RollingLanguageTierView] = []
        for item in items {
            views.append(toRollingLanguageTierView(item))
        }
        return views
    }

    static func sumRollingLanguageTierView(_ view: RollingLanguageTierView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
