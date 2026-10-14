import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered revocation estimate.
    final class TieredRevocationEstimateView {
        var code: String
        var label: String
        var endsAt: String
        var region: String
        var startsAt: String
        var reviewer: String
        var visible: String
        var acuity: String
        var budgetText: String
        var statusLabel: String

        init(code: String, label: String, endsAt: String, region: String, startsAt: String, reviewer: String, visible: String, acuity: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.region = region
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.visible = visible
            self.acuity = acuity
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRevocationEstimateView(_ item: TieredRevocationEstimate) -> TieredRevocationEstimateView {
        return TieredRevocationEstimateView(
            code: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            region: Kit.Text.truncate(item.region, limit: 64),
            startsAt: String(item.startsAt),
            reviewer: item.reviewer,
            visible: "\(item.visible)",
            acuity: String(item.acuity),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRevocationEstimateViews(_ items: [TieredRevocationEstimate]) -> [TieredRevocationEstimateView] {
        var views: [TieredRevocationEstimateView] = []
        for item in items {
            views.append(toTieredRevocationEstimateView(item))
        }
        return views
    }

    static func sumTieredRevocationEstimateView(_ view: TieredRevocationEstimateView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedStartsAt) + Double(parsedAcuity)
    }
}
