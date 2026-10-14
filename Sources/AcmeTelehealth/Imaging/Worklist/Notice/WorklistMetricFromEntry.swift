import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistEntriesForMetric(_ items: [WorklistEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveWorklistMetricsFromEntry(_ items: [WorklistEntry]) -> [WorklistMetric] {
        var out: [WorklistMetric] = []
        for item in items {
            let derived = newWorklistMetric(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchWorklistMetric(_ item: WorklistMetric) -> String {
        return normalizeWorklistEstimateCode(item.code)
    }
}
