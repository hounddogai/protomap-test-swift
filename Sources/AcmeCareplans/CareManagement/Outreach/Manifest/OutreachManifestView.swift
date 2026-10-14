import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach manifest.
    final class OutreachManifestView {
        var code: String
        var nameText: String
        var description: String
        var scoreText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, nameText: String, description: String, scoreText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.description = description
            self.scoreText = scoreText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachManifestView(_ item: OutreachManifest) -> OutreachManifestView {
        return OutreachManifestView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            description: item.description,
            scoreText: String(format: "%.2f", item.score),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachManifestViews(_ items: [OutreachManifest]) -> [OutreachManifestView] {
        var views: [OutreachManifestView] = []
        for item in items {
            views.append(toOutreachManifestView(item))
        }
        return views
    }

    static func sumOutreachManifestView(_ view: OutreachManifestView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedScore + parsedFloorValue
    }
}
