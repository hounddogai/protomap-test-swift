import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingInteractionMetricsForRequest(_ items: [PendingInteractionMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalRecallRequestsFromMetric(_ items: [PendingInteractionMetric]) -> [RegionalRecallRequest] {
        var out: [RegionalRecallRequest] = []
        for item in items {
            let derived = newRegionalRecallRequest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalRecallRequest(_ item: RegionalRecallRequest) -> String {
        return classifyRegionalInteractionWindow(item.projectedTotal())
    }
}
