import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary language profile.
    final class PrimaryLanguageProfileView {
        var code: String
        var title: String
        var createdAt: String
        var timezone: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, timezone: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.timezone = timezone
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryLanguageProfileView(_ item: PrimaryLanguageProfile) -> PrimaryLanguageProfileView {
        return PrimaryLanguageProfileView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            timezone: item.timezone,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryLanguageProfileViews(_ items: [PrimaryLanguageProfile]) -> [PrimaryLanguageProfileView] {
        var views: [PrimaryLanguageProfileView] = []
        for item in items {
            views.append(toPrimaryLanguageProfileView(item))
        }
        return views
    }

    static func sumPrimaryLanguageProfileView(_ view: PrimaryLanguageProfileView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit)
    }
}
