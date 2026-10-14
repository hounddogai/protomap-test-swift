import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackHandoffMetricsForSlot(_ items: [FallbackHandoffMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePrimaryHandoffSlotsFromMetric(_ items: [FallbackHandoffMetric]) -> [PrimaryHandoffSlot] {
        var out: [PrimaryHandoffSlot] = []
        for item in items {
            let derived = newPrimaryHandoffSlot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryHandoffSlot(_ item: PrimaryHandoffSlot) -> String {
        return normalizeFallbackHandoffMetricCode(item.code)
    }
}
