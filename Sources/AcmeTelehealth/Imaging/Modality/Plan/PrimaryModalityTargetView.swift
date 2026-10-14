import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary modality target.
    final class PrimaryModalityTargetView {
        var code: String
        var titleText: String
        var country: String
        var limit: String
        var visitMinutes: String
        var updatedAt: String
        var encounterIDText: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, country: String, limit: String, visitMinutes: String, updatedAt: String, encounterIDText: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.country = country
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.encounterIDText = encounterIDText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryModalityTargetView(_ item: PrimaryModalityTarget) -> PrimaryModalityTargetView {
        return PrimaryModalityTargetView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            country: Kit.Text.truncate(item.country, limit: 80),
            limit: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            updatedAt: String(item.updatedAt),
            encounterIDText: item.encounterID,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryModalityTargetViews(_ items: [PrimaryModalityTarget]) -> [PrimaryModalityTargetView] {
        var views: [PrimaryModalityTargetView] = []
        for item in items {
            views.append(toPrimaryModalityTargetView(item))
        }
        return views
    }

    static func sumPrimaryModalityTargetView(_ view: PrimaryModalityTargetView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedLimit) + Double(parsedVisitMinutes) + Double(parsedUpdatedAt)
    }
}
