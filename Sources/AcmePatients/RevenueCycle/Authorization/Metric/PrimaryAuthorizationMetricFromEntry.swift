import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationEntriesForMetric(_ items: [AuthorizationEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryAuthorizationMetricsFromEntry(_ items: [AuthorizationEntry]) -> [PrimaryAuthorizationMetric] {
        var out: [PrimaryAuthorizationMetric] = []
        for item in items {
            let derived = newPrimaryAuthorizationMetric(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePrimaryAuthorizationMetric(_ item: PrimaryAuthorizationMetric) -> String {
        return normalizeAuthorizationMetricCode(item.code)
    }
}
