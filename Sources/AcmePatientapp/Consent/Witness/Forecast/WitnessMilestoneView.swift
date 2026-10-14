import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness milestone.
    final class WitnessMilestoneView {
        var codeText: String
        var title: String
        var specialty: String
        var unit: String
        var encounterID: String
        var score: String
        var statusLabel: String

        init(codeText: String, title: String, specialty: String, unit: String, encounterID: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.specialty = specialty
            self.unit = unit
            self.encounterID = encounterID
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessMilestoneView(_ item: WitnessMilestone) -> WitnessMilestoneView {
        return WitnessMilestoneView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            unit: item.unit,
            encounterID: item.encounterID,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessMilestoneViews(_ items: [WitnessMilestone]) -> [WitnessMilestoneView] {
        var views: [WitnessMilestoneView] = []
        for item in items {
            views.append(toWitnessMilestoneView(item))
        }
        return views
    }

    static func sumWitnessMilestoneView(_ view: WitnessMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
