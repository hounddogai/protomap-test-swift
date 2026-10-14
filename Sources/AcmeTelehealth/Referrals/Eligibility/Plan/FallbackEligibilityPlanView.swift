import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility plan.
    final class FallbackEligibilityPlanView {
        var codeText: String
        var title: String
        var payer: String
        var label: String
        var timezone: String
        var procedureCode: String
        var checksumText: String
        var score: String
        var archived: String
        var statusLabel: String

        init(codeText: String, title: String, payer: String, label: String, timezone: String, procedureCode: String, checksumText: String, score: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.payer = payer
            self.label = label
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.checksumText = checksumText
            self.score = score
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityPlanView(_ item: FallbackEligibilityPlan) -> FallbackEligibilityPlanView {
        return FallbackEligibilityPlanView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            payer: item.payer,
            label: item.label,
            timezone: item.timezone,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            checksumText: item.checksum,
            score: String(format: "%.2f", item.score),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityPlanViews(_ items: [FallbackEligibilityPlan]) -> [FallbackEligibilityPlanView] {
        var views: [FallbackEligibilityPlanView] = []
        for item in items {
            views.append(toFallbackEligibilityPlanView(item))
        }
        return views
    }

    static func sumFallbackEligibilityPlanView(_ view: FallbackEligibilityPlanView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
