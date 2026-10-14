import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement score.
    final class StatementScoreView {
        var code: String
        var label: String
        var startsAtText: String
        var encounterIDText: String
        var margin: String
        var statusLabel: String

        init(code: String, label: String, startsAtText: String, encounterIDText: String, margin: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAtText = startsAtText
            self.encounterIDText = encounterIDText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toStatementScoreView(_ item: StatementScore) -> StatementScoreView {
        return StatementScoreView(
            code: item.code,
            label: item.label,
            startsAtText: String(item.startsAt),
            encounterIDText: item.encounterID,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementScoreViews(_ items: [StatementScore]) -> [StatementScoreView] {
        var views: [StatementScoreView] = []
        for item in items {
            views.append(toStatementScoreView(item))
        }
        return views
    }

    static func sumStatementScoreView(_ view: StatementScoreView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedStartsAt) + parsedMargin
    }
}
