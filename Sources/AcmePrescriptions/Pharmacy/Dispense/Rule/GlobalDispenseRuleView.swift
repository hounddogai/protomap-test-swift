import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global dispense rule.
    final class GlobalDispenseRuleView {
        var codeText: String
        var label: String
        var createdAtText: String
        var regionText: String
        var activeText: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, label: String, createdAtText: String, regionText: String, activeText: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.createdAtText = createdAtText
            self.regionText = regionText
            self.activeText = activeText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDispenseRuleView(_ item: GlobalDispenseRule) -> GlobalDispenseRuleView {
        return GlobalDispenseRuleView(
            codeText: item.code,
            label: item.label,
            createdAtText: String(item.createdAt),
            regionText: item.region,
            activeText: "\(item.active)",
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDispenseRuleViews(_ items: [GlobalDispenseRule]) -> [GlobalDispenseRuleView] {
        var views: [GlobalDispenseRuleView] = []
        for item in items {
            views.append(toGlobalDispenseRuleView(item))
        }
        return views
    }

    static func sumGlobalDispenseRuleView(_ view: GlobalDispenseRuleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
