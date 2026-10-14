import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalStatementEstimatesForBaseline(_ items: [GlobalStatementEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveScheduledDenialBaselinesFromEstimate(_ items: [GlobalStatementEstimate]) -> [ScheduledDenialBaseline] {
        var out: [ScheduledDenialBaseline] = []
        for item in items {
            let derived = newScheduledDenialBaseline(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyScheduledDenialBaseline(_ item: ScheduledDenialBaseline) -> String {
        return classifyGlobalStatementEstimate(item.measuredValue())
    }
}
