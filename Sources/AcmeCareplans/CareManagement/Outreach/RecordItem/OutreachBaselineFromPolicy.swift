import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultGoalPoliciesForBaseline(_ items: [DefaultGoalPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveOutreachBaselinesFromPolicy(_ items: [DefaultGoalPolicy]) -> [OutreachBaseline] {
        var out: [OutreachBaseline] = []
        for item in items {
            let derived = newOutreachBaseline(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeOutreachBaseline(_ item: OutreachBaseline) -> String {
        return classifyDefaultGoalPolicy(item.effectiveExposure())
    }
}
