import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistMappingsForRequest(_ items: [WorklistMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedModalityRequestsFromMapping(_ items: [WorklistMapping]) -> [CappedModalityRequest] {
        var out: [CappedModalityRequest] = []
        for item in items {
            let derived = newCappedModalityRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCappedModalityRequest(_ item: CappedModalityRequest) -> String {
        return classifyScheduledWorklistAdjustment(item.netTotal())
    }
}
