import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form baseline.
    final class PrimaryConsentFormBaselineView {
        var code: String
        var label: String
        var visitMinutesText: String
        var contactEmail: String
        var ownerID: String
        var ceilingText: String
        var notes: String
        var sourceText: String
        var graceDays: String
        var createdAt: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, label: String, visitMinutesText: String, contactEmail: String, ownerID: String, ceilingText: String, notes: String, sourceText: String, graceDays: String, createdAt: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutesText = visitMinutesText
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.ceilingText = ceilingText
            self.notes = notes
            self.sourceText = sourceText
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormBaselineView(_ item: PrimaryConsentFormBaseline) -> PrimaryConsentFormBaselineView {
        return PrimaryConsentFormBaselineView(
            code: item.code,
            label: item.label,
            visitMinutesText: String(item.visitMinutes),
            contactEmail: item.contactEmail,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            ceilingText: String(format: "%.2f", item.ceiling),
            notes: item.notes,
            sourceText: item.source,
            graceDays: String(item.graceDays),
            createdAt: String(item.createdAt),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormBaselineViews(_ items: [PrimaryConsentFormBaseline]) -> [PrimaryConsentFormBaselineView] {
        var views: [PrimaryConsentFormBaselineView] = []
        for item in items {
            views.append(toPrimaryConsentFormBaselineView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormBaselineView(_ view: PrimaryConsentFormBaselineView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCeiling + Double(parsedGraceDays)
    }
}
