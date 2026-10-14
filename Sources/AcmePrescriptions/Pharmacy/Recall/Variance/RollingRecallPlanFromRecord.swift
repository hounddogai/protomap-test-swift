import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInteractionRecordsForPlan(_ items: [AdaptiveInteractionRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRollingRecallPlansFromRecord(_ items: [AdaptiveInteractionRecord]) -> [RollingRecallPlan] {
        var out: [RollingRecallPlan] = []
        for item in items {
            let derived = newRollingRecallPlan(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRollingRecallPlan(_ item: RollingRecallPlan) -> String {
        return normalizeAdaptiveInteractionRecordCode(item.code)
    }
}
