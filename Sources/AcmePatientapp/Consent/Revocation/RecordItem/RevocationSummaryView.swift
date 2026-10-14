import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation summary.
    final class RevocationSummaryView {
        var code: String
        var title: String
        var visitMinutes: String
        var updatedAt: String
        var copay: String
        var reviewer: String
        var cost: String
        var archived: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, updatedAt: String, copay: String, reviewer: String, cost: String, archived: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.copay = copay
            self.reviewer = reviewer
            self.cost = cost
            self.archived = archived
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationSummaryView(_ item: RevocationSummary) -> RevocationSummaryView {
        return RevocationSummaryView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            updatedAt: String(item.updatedAt),
            copay: String(format: "%.2f", item.copay),
            reviewer: item.reviewer,
            cost: String(format: "%.2f", item.cost),
            archived: "\(item.archived)",
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationSummaryViews(_ items: [RevocationSummary]) -> [RevocationSummaryView] {
        var views: [RevocationSummaryView] = []
        for item in items {
            views.append(toRevocationSummaryView(item))
        }
        return views
    }

    static func sumRevocationSummaryView(_ view: RevocationSummaryView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedUpdatedAt) + parsedCopay
    }
}
