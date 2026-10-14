import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceAuditsForOverride(_ items: [RemittanceAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveChargeOverridesFromAudit(_ items: [RemittanceAudit]) -> [ChargeOverride] {
        var out: [ChargeOverride] = []
        for item in items {
            let derived = newChargeOverride(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileChargeOverride(_ item: ChargeOverride) -> String {
        return normalizeRemittanceAuditCode(item.code)
    }
}
