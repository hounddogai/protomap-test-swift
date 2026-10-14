import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional acuity plan claim.
    final class RegionalAcuityPlanClaimView {
        var code: String
        var nameText: String
        var visibleText: String
        var expiresAt: String
        var titleText: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, visibleText: String, expiresAt: String, titleText: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.visibleText = visibleText
            self.expiresAt = expiresAt
            self.titleText = titleText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAcuityPlanClaimView(_ item: RegionalAcuityPlanClaim) -> RegionalAcuityPlanClaimView {
        return RegionalAcuityPlanClaimView(
            code: item.code,
            nameText: item.name,
            visibleText: "\(item.visible)",
            expiresAt: String(item.expiresAt),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAcuityPlanClaimViews(_ items: [RegionalAcuityPlanClaim]) -> [RegionalAcuityPlanClaimView] {
        var views: [RegionalAcuityPlanClaimView] = []
        for item in items {
            views.append(toRegionalAcuityPlanClaimView(item))
        }
        return views
    }

    static func sumRegionalAcuityPlanClaimView(_ view: RegionalAcuityPlanClaimView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedExpiresAt) + parsedScore
    }
}
