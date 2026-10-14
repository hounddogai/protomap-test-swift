import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual bed board rollup.
    final class ManualBedBoardRollupView {
        var code: String
        var label: String
        var limitText: String
        var budget: String
        var contactEmail: String
        var amount: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, limitText: String, budget: String, contactEmail: String, amount: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limitText = limitText
            self.budget = budget
            self.contactEmail = contactEmail
            self.amount = amount
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toManualBedBoardRollupView(_ item: ManualBedBoardRollup) -> ManualBedBoardRollupView {
        return ManualBedBoardRollupView(
            code: item.code,
            label: item.label,
            limitText: String(item.limit),
            budget: String(format: "%.2f", item.budget),
            contactEmail: item.contactEmail,
            amount: String(format: "%.2f", item.amount),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualBedBoardRollupViews(_ items: [ManualBedBoardRollup]) -> [ManualBedBoardRollupView] {
        var views: [ManualBedBoardRollupView] = []
        for item in items {
            views.append(toManualBedBoardRollupView(item))
        }
        return views
    }

    static func sumManualBedBoardRollupView(_ view: ManualBedBoardRollupView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedLimit) + parsedBudget + parsedAmount
    }
}
