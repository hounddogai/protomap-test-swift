import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeEstimatesForEntry(_ items: [ChargeEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRemittanceEntriesFromEstimate(_ items: [ChargeEstimate]) -> [RemittanceEntry] {
        var out: [RemittanceEntry] = []
        for item in items {
            let derived = newRemittanceEntry(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRemittanceEntry(_ item: RemittanceEntry) -> String {
        return classifyChargeRule(item.weightedTotal())
    }
}
