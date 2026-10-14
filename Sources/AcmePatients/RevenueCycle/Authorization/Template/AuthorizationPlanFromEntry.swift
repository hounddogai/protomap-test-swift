import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialEntriesForPlan(_ items: [DenialEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAuthorizationPlansFromEntry(_ items: [DenialEntry]) -> [AuthorizationPlan] {
        var out: [AuthorizationPlan] = []
        for item in items {
            let derived = newAuthorizationPlan(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAuthorizationPlan(_ item: AuthorizationPlan) -> String {
        return denialEntryBucket(item.effectiveExposure())
    }
}
