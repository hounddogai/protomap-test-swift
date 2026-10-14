import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalHandoffPoliciesForAssignment(_ items: [SeasonalHandoffPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveHandoffAssignmentsFromPolicy(_ items: [SeasonalHandoffPolicy]) -> [HandoffAssignment] {
        var out: [HandoffAssignment] = []
        for item in items {
            let derived = newHandoffAssignment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitHandoffAssignment(_ item: HandoffAssignment) -> String {
        return fallbackHandoffPlanBucket(item.netLoad())
    }
}
