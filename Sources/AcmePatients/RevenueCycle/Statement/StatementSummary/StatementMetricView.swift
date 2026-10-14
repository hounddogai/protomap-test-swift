import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement metric.
    final class StatementMetricView {
        var code: String
        var name: String
        var ward: String
        var visitMinutesText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, name: String, ward: String, visitMinutesText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.visitMinutesText = visitMinutesText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementMetricView(_ item: StatementMetric) -> StatementMetricView {
        return StatementMetricView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 64),
            ward: item.ward,
            visitMinutesText: String(item.visitMinutes),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementMetricViews(_ items: [StatementMetric]) -> [StatementMetricView] {
        var views: [StatementMetricView] = []
        for item in items {
            views.append(toStatementMetricView(item))
        }
        return views
    }

    static func sumStatementMetricView(_ view: StatementMetricView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedExpiresAt)
    }
}
