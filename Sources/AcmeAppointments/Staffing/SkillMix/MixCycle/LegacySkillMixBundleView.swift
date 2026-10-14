import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy skill mix bundle.
    final class LegacySkillMixBundleView {
        var code: String
        var label: String
        var ceilingText: String
        var score: String
        var batchSize: String
        var priorityText: String
        var allergy: String
        var ward: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, score: String, batchSize: String, priorityText: String, allergy: String, ward: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.score = score
            self.batchSize = batchSize
            self.priorityText = priorityText
            self.allergy = allergy
            self.ward = ward
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySkillMixBundleView(_ item: LegacySkillMixBundle) -> LegacySkillMixBundleView {
        return LegacySkillMixBundleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            ceilingText: String(format: "%.2f", item.ceiling),
            score: String(format: "%.2f", item.score),
            batchSize: String(item.batchSize),
            priorityText: String(item.priority),
            allergy: item.allergy,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySkillMixBundleViews(_ items: [LegacySkillMixBundle]) -> [LegacySkillMixBundleView] {
        var views: [LegacySkillMixBundleView] = []
        for item in items {
            views.append(toLegacySkillMixBundleView(item))
        }
        return views
    }

    static func sumLegacySkillMixBundleView(_ view: LegacySkillMixBundleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCeiling + parsedScore + Double(parsedBatchSize)
    }
}
