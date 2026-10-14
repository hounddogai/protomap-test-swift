import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled cleaning claim.
    final class ScheduledCleaningClaimView {
        var code: String
        var name: String
        var updatedAtText: String
        var score: String
        var refills: String
        var statusLabel: String

        init(code: String, name: String, updatedAtText: String, score: String, refills: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAtText = updatedAtText
            self.score = score
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCleaningClaimView(_ item: ScheduledCleaningClaim) -> ScheduledCleaningClaimView {
        return ScheduledCleaningClaimView(
            code: item.code,
            name: item.name,
            updatedAtText: String(item.updatedAt),
            score: String(format: "%.2f", item.score),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCleaningClaimViews(_ items: [ScheduledCleaningClaim]) -> [ScheduledCleaningClaimView] {
        var views: [ScheduledCleaningClaimView] = []
        for item in items {
            views.append(toScheduledCleaningClaimView(item))
        }
        return views
    }

    static func sumScheduledCleaningClaimView(_ view: ScheduledCleaningClaimView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedUpdatedAt) + parsedScore + Double(parsedRefills)
    }
}
