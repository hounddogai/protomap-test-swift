import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultPlansForCycle(_ items: [ResultPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveResultCyclesFromPlan(_ items: [ResultPlan]) -> [ResultCycle] {
        var out: [ResultCycle] = []
        for item in items {
            let derived = newResultCycle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateResultCycle(_ item: ResultCycle) -> String {
        return resultPlanBucket(item.adjustedExposure())
    }
}
