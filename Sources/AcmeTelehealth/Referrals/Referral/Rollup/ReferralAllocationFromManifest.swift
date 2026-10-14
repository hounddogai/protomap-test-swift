import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkManifestsForAllocation(_ items: [NetworkManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveReferralAllocationsFromManifest(_ items: [NetworkManifest]) -> [ReferralAllocation] {
        var out: [ReferralAllocation] = []
        for item in items {
            let derived = newReferralAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeReferralAllocation(_ item: ReferralAllocation) -> String {
        return normalizeAdaptiveNetworkDraftCode(item.code)
    }
}
