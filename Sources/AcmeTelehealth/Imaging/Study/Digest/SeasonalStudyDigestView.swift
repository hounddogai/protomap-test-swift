import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal study digest.
    final class SeasonalStudyDigestView {
        var code: String
        var label: String
        var notesText: String
        var rate: String
        var attempts: String
        var statusLabel: String

        init(code: String, label: String, notesText: String, rate: String, attempts: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notesText = notesText
            self.rate = rate
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalStudyDigestView(_ item: SeasonalStudyDigest) -> SeasonalStudyDigestView {
        return SeasonalStudyDigestView(
            code: item.code,
            label: item.label,
            notesText: item.notes,
            rate: String(format: "%.2f", item.rate),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalStudyDigestViews(_ items: [SeasonalStudyDigest]) -> [SeasonalStudyDigestView] {
        var views: [SeasonalStudyDigestView] = []
        for item in items {
            views.append(toSeasonalStudyDigestView(item))
        }
        return views
    }

    static func sumSeasonalStudyDigestView(_ view: SeasonalStudyDigestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedRate + Double(parsedAttempts)
    }
}
