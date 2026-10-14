import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict recall review.
    final class StrictRecallReviewView {
        var code: String
        var label: String
        var country: String
        var summary: String
        var endsAt: String
        var clinicianID: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, country: String, summary: String, endsAt: String, clinicianID: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.country = country
            self.summary = summary
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRecallReviewView(_ item: StrictRecallReview) -> StrictRecallReviewView {
        return StrictRecallReviewView(
            code: item.code,
            label: item.label,
            country: item.country,
            summary: item.summary,
            endsAt: String(item.endsAt),
            clinicianID: item.clinicianID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRecallReviewViews(_ items: [StrictRecallReview]) -> [StrictRecallReviewView] {
        var views: [StrictRecallReviewView] = []
        for item in items {
            views.append(toStrictRecallReviewView(item))
        }
        return views
    }

    static func sumStrictRecallReviewView(_ view: StrictRecallReviewView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedEndsAt) + parsedDosageMg
    }
}
