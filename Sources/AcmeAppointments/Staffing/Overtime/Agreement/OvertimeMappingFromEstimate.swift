import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeEstimatesForMapping(_ items: [OvertimeEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveOvertimeMappingsFromEstimate(_ items: [OvertimeEstimate]) -> [OvertimeMapping] {
        var out: [OvertimeMapping] = []
        for item in items {
            let derived = newOvertimeMapping(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyOvertimeMapping(_ item: OvertimeMapping) -> String {
        return overtimeEstimateBucket(item.effectiveValue())
    }
}
