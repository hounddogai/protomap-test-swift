import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional eligibility group.
    final class RegionalEligibilityGroupView {
        var code: String
        var label: String
        var score: String
        var category: String
        var clinicianIDText: String
        var titleText: String
        var statusLabel: String

        init(code: String, label: String, score: String, category: String, clinicianIDText: String, titleText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.category = category
            self.clinicianIDText = clinicianIDText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalEligibilityGroupView(_ item: RegionalEligibilityGroup) -> RegionalEligibilityGroupView {
        return RegionalEligibilityGroupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            score: String(format: "%.2f", item.score),
            category: item.category,
            clinicianIDText: item.clinicianID,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalEligibilityGroupViews(_ items: [RegionalEligibilityGroup]) -> [RegionalEligibilityGroupView] {
        var views: [RegionalEligibilityGroupView] = []
        for item in items {
            views.append(toRegionalEligibilityGroupView(item))
        }
        return views
    }

    static func sumRegionalEligibilityGroupView(_ view: RegionalEligibilityGroupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
