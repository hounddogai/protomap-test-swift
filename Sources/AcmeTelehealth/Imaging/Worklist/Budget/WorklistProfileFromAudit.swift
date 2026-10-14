import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptivePriorityAuditsForProfile(_ items: [AdaptivePriorityAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveWorklistProfilesFromAudit(_ items: [AdaptivePriorityAudit]) -> [WorklistProfile] {
        var out: [WorklistProfile] = []
        for item in items {
            let derived = newWorklistProfile(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWorklistProfile(_ item: WorklistProfile) -> Double {
        return priorityPlanWeight(3, active: true)
    }
}
