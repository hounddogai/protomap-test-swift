import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge score.
    final class ChargeScoreView {
        var code: String
        var title: String
        var ceiling: String
        var acuityText: String
        var durationMinutes: String
        var cost: String
        var revision: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, acuityText: String, durationMinutes: String, cost: String, revision: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.acuityText = acuityText
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.revision = revision
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toChargeScoreView(_ item: ChargeScore) -> ChargeScoreView {
        return ChargeScoreView(
            code: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            acuityText: String(item.acuity),
            durationMinutes: String(item.durationMinutes),
            cost: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeScoreViews(_ items: [ChargeScore]) -> [ChargeScoreView] {
        var views: [ChargeScoreView] = []
        for item in items {
            views.append(toChargeScoreView(item))
        }
        return views
    }

    static func sumChargeScoreView(_ view: ChargeScoreView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCeiling + Double(parsedAcuity) + Double(parsedDurationMinutes)
    }
}
