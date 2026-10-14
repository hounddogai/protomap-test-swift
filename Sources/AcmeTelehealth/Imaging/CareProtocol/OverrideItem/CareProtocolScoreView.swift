import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol score.
    final class CareProtocolScoreView {
        var code: String
        var titleText: String
        var expiresAt: String
        var country: String
        var source: String
        var updatedAt: String
        var region: String
        var createdAt: String
        var budgetText: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, expiresAt: String, country: String, source: String, updatedAt: String, region: String, createdAt: String, budgetText: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.expiresAt = expiresAt
            self.country = country
            self.source = source
            self.updatedAt = updatedAt
            self.region = region
            self.createdAt = createdAt
            self.budgetText = budgetText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolScoreView(_ item: CareProtocolScore) -> CareProtocolScoreView {
        return CareProtocolScoreView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            expiresAt: String(item.expiresAt),
            country: item.country,
            source: item.source,
            updatedAt: String(item.updatedAt),
            region: Kit.Text.truncate(item.region, limit: 64),
            createdAt: String(item.createdAt),
            budgetText: String(format: "%.2f", item.budget),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolScoreViews(_ items: [CareProtocolScore]) -> [CareProtocolScoreView] {
        var views: [CareProtocolScoreView] = []
        for item in items {
            views.append(toCareProtocolScoreView(item))
        }
        return views
    }

    static func sumCareProtocolScoreView(_ view: CareProtocolScoreView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedUpdatedAt) + Double(parsedCreatedAt)
    }
}
