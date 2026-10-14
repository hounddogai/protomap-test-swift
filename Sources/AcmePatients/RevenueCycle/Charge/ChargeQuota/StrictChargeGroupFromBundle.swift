import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientClaimBundlesForGroup(_ items: [LenientClaimBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveStrictChargeGroupsFromBundle(_ items: [LenientClaimBundle]) -> [StrictChargeGroup] {
        var out: [StrictChargeGroup] = []
        for item in items {
            let derived = newStrictChargeGroup(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceStrictChargeGroup(_ item: StrictChargeGroup) -> String {
        return lenientClaimBundleBucket(item.netLoad())
    }
}
