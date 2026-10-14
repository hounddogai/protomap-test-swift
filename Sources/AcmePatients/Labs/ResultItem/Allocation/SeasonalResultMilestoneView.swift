import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal result milestone.
    final class SeasonalResultMilestoneView {
        var codeText: String
        var nameText: String
        var facility: String
        var unit: String
        var score: String
        var capacityText: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, nameText: String, facility: String, unit: String, score: String, capacityText: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.facility = facility
            self.unit = unit
            self.score = score
            self.capacityText = capacityText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalResultMilestoneView(_ item: SeasonalResultMilestone) -> SeasonalResultMilestoneView {
        return SeasonalResultMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            facility: item.facility,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            score: String(format: "%.2f", item.score),
            capacityText: String(item.capacity),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalResultMilestoneViews(_ items: [SeasonalResultMilestone]) -> [SeasonalResultMilestoneView] {
        var views: [SeasonalResultMilestoneView] = []
        for item in items {
            views.append(toSeasonalResultMilestoneView(item))
        }
        return views
    }

    static func sumSeasonalResultMilestoneView(_ view: SeasonalResultMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedScore + Double(parsedCapacity) + Double(parsedSequence)
    }
}
