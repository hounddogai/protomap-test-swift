import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient modality score.
    final class LenientModalityScoreView {
        var code: String
        var title: String
        var patientRef: String
        var priorityText: String
        var contactEmail: String
        var currencyText: String
        var allergy: String
        var externalRefText: String
        var pinned: String
        var expiresAt: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, patientRef: String, priorityText: String, contactEmail: String, currencyText: String, allergy: String, externalRefText: String, pinned: String, expiresAt: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.priorityText = priorityText
            self.contactEmail = contactEmail
            self.currencyText = currencyText
            self.allergy = allergy
            self.externalRefText = externalRefText
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toLenientModalityScoreView(_ item: LenientModalityScore) -> LenientModalityScoreView {
        return LenientModalityScoreView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            patientRef: item.patientRef,
            priorityText: String(item.priority),
            contactEmail: item.contactEmail,
            currencyText: item.currency,
            allergy: item.allergy,
            externalRefText: item.externalRef,
            pinned: "\(item.pinned)",
            expiresAt: String(item.expiresAt),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientModalityScoreViews(_ items: [LenientModalityScore]) -> [LenientModalityScoreView] {
        var views: [LenientModalityScoreView] = []
        for item in items {
            views.append(toLenientModalityScoreView(item))
        }
        return views
    }

    static func sumLenientModalityScoreView(_ view: LenientModalityScoreView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedPriority) + Double(parsedExpiresAt) + Double(parsedLimit)
    }
}
