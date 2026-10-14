import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered outreach policy.
    final class TieredOutreachPolicyView {
        var codeText: String
        var name: String
        var category: String
        var countryText: String
        var label: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, name: String, category: String, countryText: String, label: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.category = category
            self.countryText = countryText
            self.label = label
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOutreachPolicyView(_ item: TieredOutreachPolicy) -> TieredOutreachPolicyView {
        return TieredOutreachPolicyView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            category: item.category,
            countryText: Kit.Text.truncate(item.country, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOutreachPolicyViews(_ items: [TieredOutreachPolicy]) -> [TieredOutreachPolicyView] {
        var views: [TieredOutreachPolicyView] = []
        for item in items {
            views.append(toTieredOutreachPolicyView(item))
        }
        return views
    }

    static func sumTieredOutreachPolicyView(_ view: TieredOutreachPolicyView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
