import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization metric.
    final class AuthorizationMetricView {
        var code: String
        var titleText: String
        var category: String
        var descriptionText: String
        var unit: String
        var revision: String
        var channelText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, titleText: String, category: String, descriptionText: String, unit: String, revision: String, channelText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.category = category
            self.descriptionText = descriptionText
            self.unit = unit
            self.revision = revision
            self.channelText = channelText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationMetricView(_ item: AuthorizationMetric) -> AuthorizationMetricView {
        return AuthorizationMetricView(
            code: item.code,
            titleText: item.title,
            category: item.category,
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            unit: item.unit,
            revision: String(item.revision),
            channelText: item.channel,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationMetricViews(_ items: [AuthorizationMetric]) -> [AuthorizationMetricView] {
        var views: [AuthorizationMetricView] = []
        for item in items {
            views.append(toAuthorizationMetricView(item))
        }
        return views
    }

    static func sumAuthorizationMetricView(_ view: AuthorizationMetricView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRevision) + Double(parsedGraceDays)
    }
}
