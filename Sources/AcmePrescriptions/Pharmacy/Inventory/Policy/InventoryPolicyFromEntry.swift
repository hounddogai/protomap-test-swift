import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseEntriesForPolicy(_ items: [DispenseEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveInventoryPoliciesFromEntry(_ items: [DispenseEntry]) -> [InventoryPolicy] {
        var out: [InventoryPolicy] = []
        for item in items {
            let derived = newInventoryPolicy(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankInventoryPolicy(_ item: InventoryPolicy) -> String {
        return classifyGlobalDispenseMetric(item.effectiveVolume())
    }
}
