import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending formulary review.
    final class PendingFormularyReviewView {
        var codeText: String
        var nameText: String
        var ownerID: String
        var discountText: String
        var summary: String
        var diagnosisCode: String
        var visibleText: String
        var statusLabel: String

        init(codeText: String, nameText: String, ownerID: String, discountText: String, summary: String, diagnosisCode: String, visibleText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ownerID = ownerID
            self.discountText = discountText
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFormularyReviewView(_ item: PendingFormularyReview) -> PendingFormularyReviewView {
        return PendingFormularyReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            ownerID: item.ownerID,
            discountText: String(format: "%.2f", item.discount),
            summary: item.summary,
            diagnosisCode: item.diagnosisCode,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFormularyReviewViews(_ items: [PendingFormularyReview]) -> [PendingFormularyReviewView] {
        var views: [PendingFormularyReviewView] = []
        for item in items {
            views.append(toPendingFormularyReviewView(item))
        }
        return views
    }

    static func sumPendingFormularyReviewView(_ view: PendingFormularyReviewView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
