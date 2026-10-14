import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial review.
    final class DenialReviewView {
        var codeText: String
        var name: String
        var archived: String
        var durationMinutesText: String
        var currency: String
        var expiresAtText: String
        var weight: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, name: String, archived: String, durationMinutesText: String, currency: String, expiresAtText: String, weight: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.archived = archived
            self.durationMinutesText = durationMinutesText
            self.currency = currency
            self.expiresAtText = expiresAtText
            self.weight = weight
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toDenialReviewView(_ item: DenialReview) -> DenialReviewView {
        return DenialReviewView(
            codeText: item.code,
            name: item.name,
            archived: "\(item.archived)",
            durationMinutesText: String(item.durationMinutes),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            expiresAtText: String(item.expiresAt),
            weight: String(format: "%.2f", item.weight),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialReviewViews(_ items: [DenialReview]) -> [DenialReviewView] {
        var views: [DenialReviewView] = []
        for item in items {
            views.append(toDenialReviewView(item))
        }
        return views
    }

    static func sumDenialReviewView(_ view: DenialReviewView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedExpiresAt) + parsedWeight
    }
}
