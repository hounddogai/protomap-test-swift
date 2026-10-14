import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered skill mix claim.
    final class TieredSkillMixClaimView {
        var code: String
        var name: String
        var retries: String
        var allergy: String
        var weightText: String
        var categoryText: String
        var dosageMgText: String
        var segment: String
        var expiresAtText: String
        var minimumText: String
        var statusLabel: String

        init(code: String, name: String, retries: String, allergy: String, weightText: String, categoryText: String, dosageMgText: String, segment: String, expiresAtText: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.allergy = allergy
            self.weightText = weightText
            self.categoryText = categoryText
            self.dosageMgText = dosageMgText
            self.segment = segment
            self.expiresAtText = expiresAtText
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSkillMixClaimView(_ item: TieredSkillMixClaim) -> TieredSkillMixClaimView {
        return TieredSkillMixClaimView(
            code: item.code,
            name: item.name,
            retries: String(item.retries),
            allergy: item.allergy,
            weightText: String(format: "%.2f", item.weight),
            categoryText: item.category,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            segment: item.segment,
            expiresAtText: String(item.expiresAt),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSkillMixClaimViews(_ items: [TieredSkillMixClaim]) -> [TieredSkillMixClaimView] {
        var views: [TieredSkillMixClaimView] = []
        for item in items {
            views.append(toTieredSkillMixClaimView(item))
        }
        return views
    }

    static func sumTieredSkillMixClaimView(_ view: TieredSkillMixClaimView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRetries) + parsedWeight + parsedDosageMg
    }
}
