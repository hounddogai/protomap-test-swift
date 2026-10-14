import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession summary.
    final class AccessionSummaryView {
        var codeText: String
        var labelText: String
        var procedureCode: String
        var expiresAtText: String
        var graceDays: String
        var category: String
        var limitText: String
        var score: String
        var country: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, labelText: String, procedureCode: String, expiresAtText: String, graceDays: String, category: String, limitText: String, score: String, country: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.expiresAtText = expiresAtText
            self.graceDays = graceDays
            self.category = category
            self.limitText = limitText
            self.score = score
            self.country = country
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionSummaryView(_ item: AccessionSummary) -> AccessionSummaryView {
        return AccessionSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            expiresAtText: String(item.expiresAt),
            graceDays: String(item.graceDays),
            category: item.category,
            limitText: String(item.limit),
            score: String(format: "%.2f", item.score),
            country: item.country,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionSummaryViews(_ items: [AccessionSummary]) -> [AccessionSummaryView] {
        var views: [AccessionSummaryView] = []
        for item in items {
            views.append(toAccessionSummaryView(item))
        }
        return views
    }

    static func sumAccessionSummaryView(_ view: AccessionSummaryView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedGraceDays) + Double(parsedLimit)
    }
}
