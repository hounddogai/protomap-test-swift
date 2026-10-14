import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveDischargePlanBaselinesForMetric(_ items: [AdaptiveDischargePlanBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveIsolationMetricsFromBaseline(_ items: [AdaptiveDischargePlanBaseline]) -> [IsolationMetric] {
        var out: [IsolationMetric] = []
        for item in items {
            let derived = newIsolationMetric(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyIsolationMetric(_ item: IsolationMetric) -> String {
        return adaptiveDischargePlanBaselineBucket(item.netVolume())
    }
}
