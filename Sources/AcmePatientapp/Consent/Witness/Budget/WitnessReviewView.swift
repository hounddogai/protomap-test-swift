import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness review.
    final class WitnessReviewView {
        var code: String
        var name: String
        var limit: String
        var checksumText: String
        var createdAt: String
        var startsAt: String
        var approved: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, name: String, limit: String, checksumText: String, createdAt: String, startsAt: String, approved: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limit = limit
            self.checksumText = checksumText
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.approved = approved
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessReviewView(_ item: WitnessReview) -> WitnessReviewView {
        return WitnessReviewView(
            code: item.code,
            name: item.name,
            limit: String(item.limit),
            checksumText: item.checksum,
            createdAt: String(item.createdAt),
            startsAt: String(item.startsAt),
            approved: "\(item.approved)",
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessReviewViews(_ items: [WitnessReview]) -> [WitnessReviewView] {
        var views: [WitnessReviewView] = []
        for item in items {
            views.append(toWitnessReviewView(item))
        }
        return views
    }

    static func sumWitnessReviewView(_ view: WitnessReviewView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedLimit) + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
