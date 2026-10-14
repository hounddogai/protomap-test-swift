import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix quota.
    final class SkillMixQuotaView {
        var code: String
        var label: String
        var active: String
        var title: String
        var bed: String
        var payerText: String
        var region: String
        var visible: String
        var allergy: String
        var quantityText: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, active: String, title: String, bed: String, payerText: String, region: String, visible: String, allergy: String, quantityText: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.active = active
            self.title = title
            self.bed = bed
            self.payerText = payerText
            self.region = region
            self.visible = visible
            self.allergy = allergy
            self.quantityText = quantityText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixQuotaView(_ item: SkillMixQuota) -> SkillMixQuotaView {
        return SkillMixQuotaView(
            code: item.code,
            label: item.label,
            active: "\(item.active)",
            title: item.title,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            payerText: item.payer,
            region: item.region,
            visible: "\(item.visible)",
            allergy: item.allergy,
            quantityText: String(item.quantity),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixQuotaViews(_ items: [SkillMixQuota]) -> [SkillMixQuotaView] {
        var views: [SkillMixQuotaView] = []
        for item in items {
            views.append(toSkillMixQuotaView(item))
        }
        return views
    }

    static func sumSkillMixQuotaView(_ view: SkillMixQuotaView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
