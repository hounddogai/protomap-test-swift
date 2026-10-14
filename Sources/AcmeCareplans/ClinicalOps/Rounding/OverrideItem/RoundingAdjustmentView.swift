import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding adjustment.
    final class RoundingAdjustmentView {
        var code: String
        var name: String
        var startsAt: String
        var revision: String
        var reviewerText: String
        var archived: String
        var version: String
        var discount: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, revision: String, reviewerText: String, archived: String, version: String, discount: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.revision = revision
            self.reviewerText = reviewerText
            self.archived = archived
            self.version = version
            self.discount = discount
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingAdjustmentView(_ item: RoundingAdjustment) -> RoundingAdjustmentView {
        return RoundingAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            startsAt: String(item.startsAt),
            revision: String(item.revision),
            reviewerText: item.reviewer,
            archived: "\(item.archived)",
            version: String(item.version),
            discount: String(format: "%.2f", item.discount),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingAdjustmentViews(_ items: [RoundingAdjustment]) -> [RoundingAdjustmentView] {
        var views: [RoundingAdjustmentView] = []
        for item in items {
            views.append(toRoundingAdjustmentView(item))
        }
        return views
    }

    static func sumRoundingAdjustmentView(_ view: RoundingAdjustmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRevision) + Double(parsedVersion)
    }
}
