import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeGlobalIsolationSummariesForSegment(_ items: [GlobalIsolationSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultIsolationSegmentsFromSummary(_ items: [GlobalIsolationSummary]) -> [DefaultIsolationSegment] {
        var out: [DefaultIsolationSegment] = []
        for item in items {
            let derived = newDefaultIsolationSegment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultIsolationSegment(_ item: DefaultIsolationSegment) -> String {
        return classifyGlobalIsolationSummary(item.projectedValue())
    }
}
