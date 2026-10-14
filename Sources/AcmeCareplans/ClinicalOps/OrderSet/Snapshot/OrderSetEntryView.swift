import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set entry.
    final class OrderSetEntryView {
        var code: String
        var name: String
        var score: String
        var attempts: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, name: String, score: String, attempts: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.attempts = attempts
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetEntryView(_ item: OrderSetEntry) -> OrderSetEntryView {
        return OrderSetEntryView(
            code: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            attempts: String(item.attempts),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetEntryViews(_ items: [OrderSetEntry]) -> [OrderSetEntryView] {
        var views: [OrderSetEntryView] = []
        for item in items {
            views.append(toOrderSetEntryView(item))
        }
        return views
    }

    static func sumOrderSetEntryView(_ view: OrderSetEntryView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedScore + Double(parsedAttempts) + Double(parsedStartsAt)
    }
}
