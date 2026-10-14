import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultFormularyOverridesForAudit(_ items: [DefaultFormularyOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveStrictInventoryAuditsFromOverride(_ items: [DefaultFormularyOverride]) -> [StrictInventoryAudit] {
        var out: [StrictInventoryAudit] = []
        for item in items {
            let derived = newStrictInventoryAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStrictInventoryAudit(_ item: StrictInventoryAudit) -> Double {
        return fallbackFormularyAgreementWeight(9, active: true)
    }
}
