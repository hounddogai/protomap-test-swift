import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureExceptionsForAllocation(_ items: [DisclosureException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveConsentFormAllocationsFromException(_ items: [DisclosureException]) -> [AdaptiveConsentFormAllocation] {
        var out: [AdaptiveConsentFormAllocation] = []
        for item in items {
            let derived = newAdaptiveConsentFormAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveConsentFormAllocation(_ item: AdaptiveConsentFormAllocation) -> String {
        return normalizeDisclosureGroupCode(item.code)
    }
}
