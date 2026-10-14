import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped skill mix slot.
    final class CappedSkillMixSlotView {
        var code: String
        var title: String
        var dosageMg: String
        var updatedAt: String
        var weight: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, dosageMg: String, updatedAt: String, weight: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.weight = weight
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSkillMixSlotView(_ item: CappedSkillMixSlot) -> CappedSkillMixSlotView {
        return CappedSkillMixSlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            updatedAt: String(item.updatedAt),
            weight: String(format: "%.2f", item.weight),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSkillMixSlotViews(_ items: [CappedSkillMixSlot]) -> [CappedSkillMixSlotView] {
        var views: [CappedSkillMixSlotView] = []
        for item in items {
            views.append(toCappedSkillMixSlotView(item))
        }
        return views
    }

    static func sumCappedSkillMixSlotView(_ view: CappedSkillMixSlotView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedDosageMg + Double(parsedUpdatedAt) + parsedWeight
    }
}
