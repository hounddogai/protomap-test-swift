import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal witness notice.
    final class SeasonalWitnessNoticeView {
        var codeText: String
        var name: String
        var attempts: String
        var externalRef: String
        var minimum: String
        var limit: String
        var statusLabel: String

        init(codeText: String, name: String, attempts: String, externalRef: String, minimum: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.attempts = attempts
            self.externalRef = externalRef
            self.minimum = minimum
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalWitnessNoticeView(_ item: SeasonalWitnessNotice) -> SeasonalWitnessNoticeView {
        return SeasonalWitnessNoticeView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            attempts: String(item.attempts),
            externalRef: item.externalRef,
            minimum: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalWitnessNoticeViews(_ items: [SeasonalWitnessNotice]) -> [SeasonalWitnessNoticeView] {
        var views: [SeasonalWitnessNoticeView] = []
        for item in items {
            views.append(toSeasonalWitnessNoticeView(item))
        }
        return views
    }

    static func sumSeasonalWitnessNoticeView(_ view: SeasonalWitnessNoticeView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAttempts) + parsedMinimum + Double(parsedLimit)
    }
}
