import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy recall plan.
    final class LegacyRecallPlanView {
        var codeText: String
        var name: String
        var title: String
        var bedText: String
        var notesText: String
        var allergy: String
        var wardText: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, bedText: String, notesText: String, allergy: String, wardText: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.bedText = bedText
            self.notesText = notesText
            self.allergy = allergy
            self.wardText = wardText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyRecallPlanView(_ item: LegacyRecallPlan) -> LegacyRecallPlanView {
        return LegacyRecallPlanView(
            codeText: item.code,
            name: item.name,
            title: Kit.Text.truncate(item.title, limit: 80),
            bedText: item.bed,
            notesText: item.notes,
            allergy: item.allergy,
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyRecallPlanViews(_ items: [LegacyRecallPlan]) -> [LegacyRecallPlanView] {
        var views: [LegacyRecallPlanView] = []
        for item in items {
            views.append(toLegacyRecallPlanView(item))
        }
        return views
    }

    static func sumLegacyRecallPlanView(_ view: LegacyRecallPlanView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
