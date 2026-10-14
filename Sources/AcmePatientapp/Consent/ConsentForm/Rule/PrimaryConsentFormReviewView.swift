import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form review.
    final class PrimaryConsentFormReviewView {
        var code: String
        var title: String
        var clinicianID: String
        var graceDays: String
        var expiresAt: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, graceDays: String, expiresAt: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormReviewView(_ item: PrimaryConsentFormReview) -> PrimaryConsentFormReviewView {
        return PrimaryConsentFormReviewView(
            code: item.code,
            title: item.title,
            clinicianID: item.clinicianID,
            graceDays: String(item.graceDays),
            expiresAt: String(item.expiresAt),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormReviewViews(_ items: [PrimaryConsentFormReview]) -> [PrimaryConsentFormReviewView] {
        var views: [PrimaryConsentFormReviewView] = []
        for item in items {
            views.append(toPrimaryConsentFormReviewView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormReviewView(_ view: PrimaryConsentFormReviewView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt)
    }
}
