import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal panel score.
    final class SeasonalPanelScoreView {
        var code: String
        var name: String
        var createdAt: String
        var patientRef: String
        var checksum: String
        var allergy: String
        var priority: String
        var acuity: String
        var categoryText: String
        var statusLabel: String

        init(code: String, name: String, createdAt: String, patientRef: String, checksum: String, allergy: String, priority: String, acuity: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.patientRef = patientRef
            self.checksum = checksum
            self.allergy = allergy
            self.priority = priority
            self.acuity = acuity
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalPanelScoreView(_ item: SeasonalPanelScore) -> SeasonalPanelScoreView {
        return SeasonalPanelScoreView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            createdAt: String(item.createdAt),
            patientRef: item.patientRef,
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            allergy: item.allergy,
            priority: String(item.priority),
            acuity: String(item.acuity),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalPanelScoreViews(_ items: [SeasonalPanelScore]) -> [SeasonalPanelScoreView] {
        var views: [SeasonalPanelScoreView] = []
        for item in items {
            views.append(toSeasonalPanelScoreView(item))
        }
        return views
    }

    static func sumSeasonalPanelScoreView(_ view: SeasonalPanelScoreView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedPriority) + Double(parsedAcuity)
    }
}
