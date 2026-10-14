import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingRecallPlansForTemplate(_ items: [RollingRecallPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveLegacyRecallTemplatesFromPlan(_ items: [RollingRecallPlan]) -> [LegacyRecallTemplate] {
        var out: [LegacyRecallTemplate] = []
        for item in items {
            let derived = newLegacyRecallTemplate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacyRecallTemplate(_ item: LegacyRecallTemplate) -> Double {
        return rollingRecallPlanWeight(4, active: true)
    }
}
