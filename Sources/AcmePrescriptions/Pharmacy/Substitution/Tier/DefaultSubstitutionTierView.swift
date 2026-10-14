import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default substitution tier.
    final class DefaultSubstitutionTierView {
        var code: String
        var nameText: String
        var weight: String
        var active: String
        var allergy: String
        var retries: String
        var payerText: String
        var dosageMgText: String
        var categoryText: String
        var source: String
        var version: String
        var statusLabel: String

        init(code: String, nameText: String, weight: String, active: String, allergy: String, retries: String, payerText: String, dosageMgText: String, categoryText: String, source: String, version: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.weight = weight
            self.active = active
            self.allergy = allergy
            self.retries = retries
            self.payerText = payerText
            self.dosageMgText = dosageMgText
            self.categoryText = categoryText
            self.source = source
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultSubstitutionTierView(_ item: DefaultSubstitutionTier) -> DefaultSubstitutionTierView {
        return DefaultSubstitutionTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            weight: String(format: "%.2f", item.weight),
            active: "\(item.active)",
            allergy: item.allergy,
            retries: String(item.retries),
            payerText: item.payer,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            categoryText: item.category,
            source: item.source,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultSubstitutionTierViews(_ items: [DefaultSubstitutionTier]) -> [DefaultSubstitutionTierView] {
        var views: [DefaultSubstitutionTierView] = []
        for item in items {
            views.append(toDefaultSubstitutionTierView(item))
        }
        return views
    }

    static func sumDefaultSubstitutionTierView(_ view: DefaultSubstitutionTierView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedWeight + Double(parsedRetries) + parsedDosageMg
    }
}
