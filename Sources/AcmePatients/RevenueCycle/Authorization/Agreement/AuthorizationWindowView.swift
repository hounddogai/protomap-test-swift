import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization window.
    final class AuthorizationWindowView {
        var code: String
        var nameText: String
        var countryText: String
        var ratio: String
        var title: String
        var timezone: String
        var summary: String
        var retries: String
        var description: String
        var statusLabel: String

        init(code: String, nameText: String, countryText: String, ratio: String, title: String, timezone: String, summary: String, retries: String, description: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.countryText = countryText
            self.ratio = ratio
            self.title = title
            self.timezone = timezone
            self.summary = summary
            self.retries = retries
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationWindowView(_ item: AuthorizationWindow) -> AuthorizationWindowView {
        return AuthorizationWindowView(
            code: item.code,
            nameText: item.name,
            countryText: Kit.Text.truncate(item.country, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            title: Kit.Text.truncate(item.title, limit: 120),
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            summary: item.summary,
            retries: String(item.retries),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationWindowViews(_ items: [AuthorizationWindow]) -> [AuthorizationWindowView] {
        var views: [AuthorizationWindowView] = []
        for item in items {
            views.append(toAuthorizationWindowView(item))
        }
        return views
    }

    static func sumAuthorizationWindowView(_ view: AuthorizationWindowView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedRatio + Double(parsedRetries)
    }
}
