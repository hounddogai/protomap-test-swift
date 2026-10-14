import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict substitution threshold.
    final class StrictSubstitutionThresholdView {
        var code: String
        var label: String
        var discount: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, discount: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSubstitutionThresholdView(_ item: StrictSubstitutionThreshold) -> StrictSubstitutionThresholdView {
        return StrictSubstitutionThresholdView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSubstitutionThresholdViews(_ items: [StrictSubstitutionThreshold]) -> [StrictSubstitutionThresholdView] {
        var views: [StrictSubstitutionThresholdView] = []
        for item in items {
            views.append(toStrictSubstitutionThresholdView(item))
        }
        return views
    }

    static func sumStrictSubstitutionThresholdView(_ view: StrictSubstitutionThresholdView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
