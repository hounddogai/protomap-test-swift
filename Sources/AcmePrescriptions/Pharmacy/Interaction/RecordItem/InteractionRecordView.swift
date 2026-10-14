import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction record.
    final class InteractionRecordView {
        var code: String
        var name: String
        var archived: String
        var rate: String
        var updatedAt: String
        var currencyText: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, archived: String, rate: String, updatedAt: String, currencyText: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.rate = rate
            self.updatedAt = updatedAt
            self.currencyText = currencyText
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionRecordView(_ item: InteractionRecord) -> InteractionRecordView {
        return InteractionRecordView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            archived: "\(item.archived)",
            rate: String(format: "%.2f", item.rate),
            updatedAt: String(item.updatedAt),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionRecordViews(_ items: [InteractionRecord]) -> [InteractionRecordView] {
        var views: [InteractionRecordView] = []
        for item in items {
            views.append(toInteractionRecordView(item))
        }
        return views
    }

    static func sumInteractionRecordView(_ view: InteractionRecordView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedRate + Double(parsedUpdatedAt) + parsedScore
    }
}
