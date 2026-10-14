import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result ledger.
    final class ResultLedgerView {
        var codeText: String
        var name: String
        var channel: String
        var reviewerText: String
        var externalRefText: String
        var clinicianIDText: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, channel: String, reviewerText: String, externalRefText: String, clinicianIDText: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.channel = channel
            self.reviewerText = reviewerText
            self.externalRefText = externalRefText
            self.clinicianIDText = clinicianIDText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toResultLedgerView(_ item: ResultLedger) -> ResultLedgerView {
        return ResultLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            channel: item.channel,
            reviewerText: item.reviewer,
            externalRefText: item.externalRef,
            clinicianIDText: item.clinicianID,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultLedgerViews(_ items: [ResultLedger]) -> [ResultLedgerView] {
        var views: [ResultLedgerView] = []
        for item in items {
            views.append(toResultLedgerView(item))
        }
        return views
    }

    static func sumResultLedgerView(_ view: ResultLedgerView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
