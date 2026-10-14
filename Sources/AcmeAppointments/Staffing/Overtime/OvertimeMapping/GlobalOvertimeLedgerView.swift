import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global overtime ledger.
    final class GlobalOvertimeLedgerView {
        var codeText: String
        var nameText: String
        var clinicianID: String
        var score: String
        var quantityText: String
        var reviewerText: String
        var notes: String
        var bedText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, nameText: String, clinicianID: String, score: String, quantityText: String, reviewerText: String, notes: String, bedText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.clinicianID = clinicianID
            self.score = score
            self.quantityText = quantityText
            self.reviewerText = reviewerText
            self.notes = notes
            self.bedText = bedText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalOvertimeLedgerView(_ item: GlobalOvertimeLedger) -> GlobalOvertimeLedgerView {
        return GlobalOvertimeLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            clinicianID: item.clinicianID,
            score: String(format: "%.2f", item.score),
            quantityText: String(item.quantity),
            reviewerText: item.reviewer,
            notes: Kit.Text.truncate(item.notes, limit: 120),
            bedText: item.bed,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalOvertimeLedgerViews(_ items: [GlobalOvertimeLedger]) -> [GlobalOvertimeLedgerView] {
        var views: [GlobalOvertimeLedgerView] = []
        for item in items {
            views.append(toGlobalOvertimeLedgerView(item))
        }
        return views
    }

    static func sumGlobalOvertimeLedgerView(_ view: GlobalOvertimeLedgerView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedScore + Double(parsedQuantity)
    }
}
