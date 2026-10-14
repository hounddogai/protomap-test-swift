import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending alert review.
    final class PendingAlertReviewView {
        var code: String
        var labelText: String
        var reviewerText: String
        var approved: String
        var ownerID: String
        var acuity: String
        var quantityText: String
        var category: String
        var encounterIDText: String
        var nameText: String
        var timezone: String
        var statusLabel: String

        init(code: String, labelText: String, reviewerText: String, approved: String, ownerID: String, acuity: String, quantityText: String, category: String, encounterIDText: String, nameText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.reviewerText = reviewerText
            self.approved = approved
            self.ownerID = ownerID
            self.acuity = acuity
            self.quantityText = quantityText
            self.category = category
            self.encounterIDText = encounterIDText
            self.nameText = nameText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAlertReviewView(_ item: PendingAlertReview) -> PendingAlertReviewView {
        return PendingAlertReviewView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            approved: "\(item.approved)",
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            acuity: String(item.acuity),
            quantityText: String(item.quantity),
            category: Kit.Text.truncate(item.category, limit: 40),
            encounterIDText: item.encounterID,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAlertReviewViews(_ items: [PendingAlertReview]) -> [PendingAlertReviewView] {
        var views: [PendingAlertReviewView] = []
        for item in items {
            views.append(toPendingAlertReviewView(item))
        }
        return views
    }

    static func sumPendingAlertReviewView(_ view: PendingAlertReviewView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedAcuity) + Double(parsedQuantity)
    }
}
