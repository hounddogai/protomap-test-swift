import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeWeightedOrderSetPoliciesForAgreement(_ items: [WeightedOrderSetPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDefaultAlertAgreementsFromPolicy(_ items: [WeightedOrderSetPolicy]) -> [DefaultAlertAgreement] {
        var out: [DefaultAlertAgreement] = []
        for item in items {
            let derived = newDefaultAlertAgreement(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreDefaultAlertAgreement(_ item: DefaultAlertAgreement) -> String {
        return normalizeOrderSetRuleCode(item.code)
    }
}
