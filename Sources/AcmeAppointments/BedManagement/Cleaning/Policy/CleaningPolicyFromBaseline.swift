import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanBaselinesForPolicy(_ items: [DischargePlanBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCleaningPoliciesFromBaseline(_ items: [DischargePlanBaseline]) -> [CleaningPolicy] {
        var out: [CleaningPolicy] = []
        for item in items {
            let derived = newCleaningPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCleaningPolicy(_ item: CleaningPolicy) -> Double {
        return dischargePlanDigestWeight(8, active: true)
    }
}
