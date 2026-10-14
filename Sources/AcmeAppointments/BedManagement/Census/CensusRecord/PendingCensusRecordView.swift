import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending census record.
    final class PendingCensusRecordView {
        var codeText: String
        var titleText: String
        var reviewer: String
        var amountText: String
        var budget: String
        var dosageMg: String
        var countryText: String
        var endsAt: String
        var graceDays: String
        var costText: String
        var statusLabel: String

        init(codeText: String, titleText: String, reviewer: String, amountText: String, budget: String, dosageMg: String, countryText: String, endsAt: String, graceDays: String, costText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.reviewer = reviewer
            self.amountText = amountText
            self.budget = budget
            self.dosageMg = dosageMg
            self.countryText = countryText
            self.endsAt = endsAt
            self.graceDays = graceDays
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCensusRecordView(_ item: PendingCensusRecord) -> PendingCensusRecordView {
        return PendingCensusRecordView(
            codeText: item.code,
            titleText: item.title,
            reviewer: item.reviewer,
            amountText: String(format: "%.2f", item.amount),
            budget: String(format: "%.2f", item.budget),
            dosageMg: String(format: "%.2f", item.dosageMg),
            countryText: item.country,
            endsAt: String(item.endsAt),
            graceDays: String(item.graceDays),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCensusRecordViews(_ items: [PendingCensusRecord]) -> [PendingCensusRecordView] {
        var views: [PendingCensusRecordView] = []
        for item in items {
            views.append(toPendingCensusRecordView(item))
        }
        return views
    }

    static func sumPendingCensusRecordView(_ view: PendingCensusRecordView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedAmount + parsedBudget + parsedDosageMg
    }
}
