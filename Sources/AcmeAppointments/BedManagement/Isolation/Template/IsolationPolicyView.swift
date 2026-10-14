import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation policy.
    final class IsolationPolicyView {
        var codeText: String
        var label: String
        var category: String
        var facility: String
        var region: String
        var currencyText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, label: String, category: String, facility: String, region: String, currencyText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.category = category
            self.facility = facility
            self.region = region
            self.currencyText = currencyText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationPolicyView(_ item: IsolationPolicy) -> IsolationPolicyView {
        return IsolationPolicyView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            category: Kit.Text.truncate(item.category, limit: 40),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            region: Kit.Text.truncate(item.region, limit: 64),
            currencyText: item.currency,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationPolicyViews(_ items: [IsolationPolicy]) -> [IsolationPolicyView] {
        var views: [IsolationPolicyView] = []
        for item in items {
            views.append(toIsolationPolicyView(item))
        }
        return views
    }

    static func sumIsolationPolicyView(_ view: IsolationPolicyView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
