import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered reference range review.
    final class TieredReferenceRangeReviewView {
        var codeText: String
        var label: String
        var minimum: String
        var graceDays: String
        var reviewer: String
        var endsAt: String
        var contactEmail: String
        var patientRef: String
        var encounterID: String
        var approved: String
        var statusLabel: String

        init(codeText: String, label: String, minimum: String, graceDays: String, reviewer: String, endsAt: String, contactEmail: String, patientRef: String, encounterID: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.minimum = minimum
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.encounterID = encounterID
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReferenceRangeReviewView(_ item: TieredReferenceRangeReview) -> TieredReferenceRangeReviewView {
        return TieredReferenceRangeReviewView(
            codeText: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            graceDays: String(item.graceDays),
            reviewer: item.reviewer,
            endsAt: String(item.endsAt),
            contactEmail: item.contactEmail,
            patientRef: item.patientRef,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReferenceRangeReviewViews(_ items: [TieredReferenceRangeReview]) -> [TieredReferenceRangeReviewView] {
        var views: [TieredReferenceRangeReviewView] = []
        for item in items {
            views.append(toTieredReferenceRangeReviewView(item))
        }
        return views
    }

    static func sumTieredReferenceRangeReviewView(_ view: TieredReferenceRangeReviewView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMinimum + Double(parsedGraceDays) + Double(parsedEndsAt)
    }
}
