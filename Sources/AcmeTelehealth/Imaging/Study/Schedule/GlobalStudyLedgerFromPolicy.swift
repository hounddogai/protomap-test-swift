import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLegacyPriorityPoliciesForLedger(_ items: [LegacyPriorityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalStudyLedgersFromPolicy(_ items: [LegacyPriorityPolicy]) -> [GlobalStudyLedger] {
        var out: [GlobalStudyLedger] = []
        for item in items {
            let derived = newGlobalStudyLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalStudyLedger(_ item: GlobalStudyLedger) -> String {
        return rollingPriorityAssignmentBucket(item.projectedLoad())
    }
}
