import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual skill mix milestone.
    final class ManualSkillMixMilestoneView {
        var code: String
        var label: String
        var amountText: String
        var phoneText: String
        var reviewerText: String
        var title: String
        var statusLabel: String

        init(code: String, label: String, amountText: String, phoneText: String, reviewerText: String, title: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amountText = amountText
            self.phoneText = phoneText
            self.reviewerText = reviewerText
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toManualSkillMixMilestoneView(_ item: ManualSkillMixMilestone) -> ManualSkillMixMilestoneView {
        return ManualSkillMixMilestoneView(
            code: item.code,
            label: item.label,
            amountText: String(format: "%.2f", item.amount),
            phoneText: item.phone,
            reviewerText: item.reviewer,
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSkillMixMilestoneViews(_ items: [ManualSkillMixMilestone]) -> [ManualSkillMixMilestoneView] {
        var views: [ManualSkillMixMilestoneView] = []
        for item in items {
            views.append(toManualSkillMixMilestoneView(item))
        }
        return views
    }

    static func sumManualSkillMixMilestoneView(_ view: ManualSkillMixMilestoneView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
