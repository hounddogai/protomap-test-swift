import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal language checkpoint.
    final class SeasonalLanguageCheckpointView {
        var code: String
        var title: String
        var version: String
        var minimum: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, version: String, minimum: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.version = version
            self.minimum = minimum
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalLanguageCheckpointView(_ item: SeasonalLanguageCheckpoint) -> SeasonalLanguageCheckpointView {
        return SeasonalLanguageCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            version: String(item.version),
            minimum: String(format: "%.2f", item.minimum),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalLanguageCheckpointViews(_ items: [SeasonalLanguageCheckpoint]) -> [SeasonalLanguageCheckpointView] {
        var views: [SeasonalLanguageCheckpointView] = []
        for item in items {
            views.append(toSeasonalLanguageCheckpointView(item))
        }
        return views
    }

    static func sumSeasonalLanguageCheckpointView(_ view: SeasonalLanguageCheckpointView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVersion) + parsedMinimum
    }
}
