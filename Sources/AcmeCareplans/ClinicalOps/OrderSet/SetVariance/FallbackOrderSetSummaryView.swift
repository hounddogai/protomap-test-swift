import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback order set summary.
    final class FallbackOrderSetSummaryView {
        var codeText: String
        var title: String
        var clinicianID: String
        var checksum: String
        var archived: String
        var amount: String
        var statusLabel: String

        init(codeText: String, title: String, clinicianID: String, checksum: String, archived: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.archived = archived
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackOrderSetSummaryView(_ item: FallbackOrderSetSummary) -> FallbackOrderSetSummaryView {
        return FallbackOrderSetSummaryView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            clinicianID: item.clinicianID,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackOrderSetSummaryViews(_ items: [FallbackOrderSetSummary]) -> [FallbackOrderSetSummaryView] {
        var views: [FallbackOrderSetSummaryView] = []
        for item in items {
            views.append(toFallbackOrderSetSummaryView(item))
        }
        return views
    }

    static func sumFallbackOrderSetSummaryView(_ view: FallbackOrderSetSummaryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
