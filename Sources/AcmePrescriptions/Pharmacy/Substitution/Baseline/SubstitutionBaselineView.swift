import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution baseline.
    final class SubstitutionBaselineView {
        var codeText: String
        var title: String
        var currency: String
        var checksumText: String
        var contactEmail: String
        var diagnosisCode: String
        var score: String
        var statusLabel: String

        init(codeText: String, title: String, currency: String, checksumText: String, contactEmail: String, diagnosisCode: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.currency = currency
            self.checksumText = checksumText
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionBaselineView(_ item: SubstitutionBaseline) -> SubstitutionBaselineView {
        return SubstitutionBaselineView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            currency: item.currency,
            checksumText: Kit.Text.truncate(item.checksum, limit: 80),
            contactEmail: item.contactEmail,
            diagnosisCode: item.diagnosisCode,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionBaselineViews(_ items: [SubstitutionBaseline]) -> [SubstitutionBaselineView] {
        var views: [SubstitutionBaselineView] = []
        for item in items {
            views.append(toSubstitutionBaselineView(item))
        }
        return views
    }

    static func sumSubstitutionBaselineView(_ view: SubstitutionBaselineView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
