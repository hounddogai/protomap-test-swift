import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction manifest.
    final class InteractionManifestView {
        var codeText: String
        var nameText: String
        var attempts: String
        var scoreText: String
        var facilityText: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, nameText: String, attempts: String, scoreText: String, facilityText: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.attempts = attempts
            self.scoreText = scoreText
            self.facilityText = facilityText
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionManifestView(_ item: InteractionManifest) -> InteractionManifestView {
        return InteractionManifestView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            attempts: String(item.attempts),
            scoreText: String(format: "%.2f", item.score),
            facilityText: item.facility,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionManifestViews(_ items: [InteractionManifest]) -> [InteractionManifestView] {
        var views: [InteractionManifestView] = []
        for item in items {
            views.append(toInteractionManifestView(item))
        }
        return views
    }

    static func sumInteractionManifestView(_ view: InteractionManifestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedAttempts) + parsedScore + Double(parsedGraceDays)
    }
}
