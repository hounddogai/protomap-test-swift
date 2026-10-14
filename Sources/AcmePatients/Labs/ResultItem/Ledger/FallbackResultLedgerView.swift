import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback result ledger.
    final class FallbackResultLedgerView {
        var code: String
        var name: String
        var cost: String
        var externalRefText: String
        var specialty: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, name: String, cost: String, externalRefText: String, specialty: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.externalRefText = externalRefText
            self.specialty = specialty
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackResultLedgerView(_ item: FallbackResultLedger) -> FallbackResultLedgerView {
        return FallbackResultLedgerView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            externalRefText: item.externalRef,
            specialty: item.specialty,
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackResultLedgerViews(_ items: [FallbackResultLedger]) -> [FallbackResultLedgerView] {
        var views: [FallbackResultLedgerView] = []
        for item in items {
            views.append(toFallbackResultLedgerView(item))
        }
        return views
    }

    static func sumFallbackResultLedgerView(_ view: FallbackResultLedgerView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
