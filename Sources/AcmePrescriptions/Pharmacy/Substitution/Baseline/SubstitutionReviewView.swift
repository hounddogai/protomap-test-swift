import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution review.
    final class SubstitutionReviewView {
        var codeText: String
        var title: String
        var ratioText: String
        var allergy: String
        var dosageMg: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, title: String, ratioText: String, allergy: String, dosageMg: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ratioText = ratioText
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionReviewView(_ item: SubstitutionReview) -> SubstitutionReviewView {
        return SubstitutionReviewView(
            codeText: item.code,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            allergy: item.allergy,
            dosageMg: String(format: "%.2f", item.dosageMg),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionReviewViews(_ items: [SubstitutionReview]) -> [SubstitutionReviewView] {
        var views: [SubstitutionReviewView] = []
        for item in items {
            views.append(toSubstitutionReviewView(item))
        }
        return views
    }

    static func sumSubstitutionReviewView(_ view: SubstitutionReviewView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRatio + parsedDosageMg + Double(parsedSequence)
    }
}
