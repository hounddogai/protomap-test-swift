import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryChargeTargetsForGroup(_ items: [PrimaryChargeTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveRemittanceGroupsFromTarget(_ items: [PrimaryChargeTarget]) -> [AdaptiveRemittanceGroup] {
        var out: [AdaptiveRemittanceGroup] = []
        for item in items {
            let derived = newAdaptiveRemittanceGroup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAdaptiveRemittanceGroup(_ item: AdaptiveRemittanceGroup) -> Double {
        return chargeLedgerWeight(1, active: true)
    }
}
