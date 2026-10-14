import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionAllocationsForClaim(_ items: [InteractionAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientSubstitutionClaimsFromAllocation(_ items: [InteractionAllocation]) -> [LenientSubstitutionClaim] {
        var out: [LenientSubstitutionClaim] = []
        for item in items {
            let derived = newLenientSubstitutionClaim(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planLenientSubstitutionClaim(_ item: LenientSubstitutionClaim) -> String {
        return normalizeInteractionMetricCode(item.code)
    }
}
