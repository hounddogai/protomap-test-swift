import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary shift preference.
    final class PrimaryShiftPreferenceView {
        var codeText: String
        var title: String
        var channel: String
        var quantityText: String
        var scoreText: String
        var startsAt: String
        var active: String
        var revision: String
        var description: String
        var statusLabel: String

        init(codeText: String, title: String, channel: String, quantityText: String, scoreText: String, startsAt: String, active: String, revision: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.channel = channel
            self.quantityText = quantityText
            self.scoreText = scoreText
            self.startsAt = startsAt
            self.active = active
            self.revision = revision
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryShiftPreferenceView(_ item: PrimaryShiftPreference) -> PrimaryShiftPreferenceView {
        return PrimaryShiftPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            channel: Kit.Text.truncate(item.channel, limit: 120),
            quantityText: String(item.quantity),
            scoreText: String(format: "%.2f", item.score),
            startsAt: String(item.startsAt),
            active: "\(item.active)",
            revision: String(item.revision),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryShiftPreferenceViews(_ items: [PrimaryShiftPreference]) -> [PrimaryShiftPreferenceView] {
        var views: [PrimaryShiftPreferenceView] = []
        for item in items {
            views.append(toPrimaryShiftPreferenceView(item))
        }
        return views
    }

    static func sumPrimaryShiftPreferenceView(_ view: PrimaryShiftPreferenceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedQuantity) + parsedScore + Double(parsedStartsAt)
    }
}
