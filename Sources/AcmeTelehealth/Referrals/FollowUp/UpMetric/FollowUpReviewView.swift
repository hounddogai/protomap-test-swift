import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up review.
    final class FollowUpReviewView {
        var code: String
        var label: String
        var clinicianID: String
        var encounterIDText: String
        var contactEmail: String
        var retries: String
        var minimumText: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, clinicianID: String, encounterIDText: String, contactEmail: String, retries: String, minimumText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.encounterIDText = encounterIDText
            self.contactEmail = contactEmail
            self.retries = retries
            self.minimumText = minimumText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpReviewView(_ item: FollowUpReview) -> FollowUpReviewView {
        return FollowUpReviewView(
            code: item.code,
            label: item.label,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            encounterIDText: item.encounterID,
            contactEmail: item.contactEmail,
            retries: String(item.retries),
            minimumText: String(format: "%.2f", item.minimum),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpReviewViews(_ items: [FollowUpReview]) -> [FollowUpReviewView] {
        var views: [FollowUpReviewView] = []
        for item in items {
            views.append(toFollowUpReviewView(item))
        }
        return views
    }

    static func sumFollowUpReviewView(_ view: FollowUpReviewView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRetries) + parsedMinimum
    }
}
