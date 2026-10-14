import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling task policy.
    final class RollingTaskPolicyView {
        var code: String
        var label: String
        var maximum: String
        var title: String
        var category: String
        var currency: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, maximum: String, title: String, category: String, currency: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.title = title
            self.category = category
            self.currency = currency
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toRollingTaskPolicyView(_ item: RollingTaskPolicy) -> RollingTaskPolicyView {
        return RollingTaskPolicyView(
            code: item.code,
            label: item.label,
            maximum: String(format: "%.2f", item.maximum),
            title: Kit.Text.truncate(item.title, limit: 40),
            category: item.category,
            currency: Kit.Text.truncate(item.currency, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingTaskPolicyViews(_ items: [RollingTaskPolicy]) -> [RollingTaskPolicyView] {
        var views: [RollingTaskPolicyView] = []
        for item in items {
            views.append(toRollingTaskPolicyView(item))
        }
        return views
    }

    static func sumRollingTaskPolicyView(_ view: RollingTaskPolicyView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMaximum + parsedDosageMg
    }
}
