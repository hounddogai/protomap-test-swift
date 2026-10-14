import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim review.
    final class ClaimReviewView {
        var codeText: String
        var name: String
        var budgetText: String
        var margin: String
        var minimumText: String
        var expiresAt: String
        var visible: String
        var batchSizeText: String
        var checksumText: String
        var visitMinutes: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, name: String, budgetText: String, margin: String, minimumText: String, expiresAt: String, visible: String, batchSizeText: String, checksumText: String, visitMinutes: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.budgetText = budgetText
            self.margin = margin
            self.minimumText = minimumText
            self.expiresAt = expiresAt
            self.visible = visible
            self.batchSizeText = batchSizeText
            self.checksumText = checksumText
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toClaimReviewView(_ item: ClaimReview) -> ClaimReviewView {
        return ClaimReviewView(
            codeText: item.code,
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            margin: String(format: "%.2f", item.margin),
            minimumText: String(format: "%.2f", item.minimum),
            expiresAt: String(item.expiresAt),
            visible: "\(item.visible)",
            batchSizeText: String(item.batchSize),
            checksumText: item.checksum,
            visitMinutes: String(item.visitMinutes),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimReviewViews(_ items: [ClaimReview]) -> [ClaimReviewView] {
        var views: [ClaimReviewView] = []
        for item in items {
            views.append(toClaimReviewView(item))
        }
        return views
    }

    static func sumClaimReviewView(_ view: ClaimReviewView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedBudget + parsedMargin + parsedMinimum
    }
}
