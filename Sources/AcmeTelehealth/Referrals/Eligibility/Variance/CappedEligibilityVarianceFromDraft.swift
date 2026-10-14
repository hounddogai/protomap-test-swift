import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureDraftsForVariance(_ items: [ClosureDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedEligibilityVariancesFromDraft(_ items: [ClosureDraft]) -> [CappedEligibilityVariance] {
        var out: [CappedEligibilityVariance] = []
        for item in items {
            let derived = newCappedEligibilityVariance(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCappedEligibilityVariance(_ item: CappedEligibilityVariance) -> String {
        return closureDraftBucket(item.effectiveExposure())
    }
}
