import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix adjustment.
    final class SkillMixAdjustmentView {
        var code: String
        var label: String
        var checksum: String
        var visibleText: String
        var ownerID: String
        var currency: String
        var clinicianID: String
        var name: String
        var title: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, visibleText: String, ownerID: String, currency: String, clinicianID: String, name: String, title: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.visibleText = visibleText
            self.ownerID = ownerID
            self.currency = currency
            self.clinicianID = clinicianID
            self.name = name
            self.title = title
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixAdjustmentView(_ item: SkillMixAdjustment) -> SkillMixAdjustmentView {
        return SkillMixAdjustmentView(
            code: item.code,
            label: item.label,
            checksum: item.checksum,
            visibleText: "\(item.visible)",
            ownerID: item.ownerID,
            currency: item.currency,
            clinicianID: item.clinicianID,
            name: item.name,
            title: item.title,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixAdjustmentViews(_ items: [SkillMixAdjustment]) -> [SkillMixAdjustmentView] {
        var views: [SkillMixAdjustmentView] = []
        for item in items {
            views.append(toSkillMixAdjustmentView(item))
        }
        return views
    }

    static func sumSkillMixAdjustmentView(_ view: SkillMixAdjustmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
