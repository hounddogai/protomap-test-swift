import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score baseline.
    final class RiskScoreBaselineView {
        var code: String
        var name: String
        var refills: String
        var updatedAt: String
        var timezone: String
        var visitMinutes: String
        var weight: String
        var copay: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, refills: String, updatedAt: String, timezone: String, visitMinutes: String, weight: String, copay: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.refills = refills
            self.updatedAt = updatedAt
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.copay = copay
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreBaselineView(_ item: RiskScoreBaseline) -> RiskScoreBaselineView {
        return RiskScoreBaselineView(
            code: item.code,
            name: item.name,
            refills: String(item.refills),
            updatedAt: String(item.updatedAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            visitMinutes: String(item.visitMinutes),
            weight: String(format: "%.2f", item.weight),
            copay: String(format: "%.2f", item.copay),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreBaselineViews(_ items: [RiskScoreBaseline]) -> [RiskScoreBaselineView] {
        var views: [RiskScoreBaselineView] = []
        for item in items {
            views.append(toRiskScoreBaselineView(item))
        }
        return views
    }

    static func sumRiskScoreBaselineView(_ view: RiskScoreBaselineView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRefills) + Double(parsedUpdatedAt) + Double(parsedVisitMinutes)
    }
}
