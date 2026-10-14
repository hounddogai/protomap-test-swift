import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal handoff milestone.
    final class SeasonalHandoffMilestoneView {
        var code: String
        var label: String
        var score: String
        var startsAt: String
        var dosageMgText: String
        var capacity: String
        var phone: String
        var archivedText: String
        var statusLabel: String

        init(code: String, label: String, score: String, startsAt: String, dosageMgText: String, capacity: String, phone: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAt = startsAt
            self.dosageMgText = dosageMgText
            self.capacity = capacity
            self.phone = phone
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalHandoffMilestoneView(_ item: SeasonalHandoffMilestone) -> SeasonalHandoffMilestoneView {
        return SeasonalHandoffMilestoneView(
            code: item.code,
            label: item.label,
            score: String(format: "%.2f", item.score),
            startsAt: String(item.startsAt),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalHandoffMilestoneViews(_ items: [SeasonalHandoffMilestone]) -> [SeasonalHandoffMilestoneView] {
        var views: [SeasonalHandoffMilestoneView] = []
        for item in items {
            views.append(toSeasonalHandoffMilestoneView(item))
        }
        return views
    }

    static func sumSeasonalHandoffMilestoneView(_ view: SeasonalHandoffMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedScore + Double(parsedStartsAt) + parsedDosageMg
    }
}
