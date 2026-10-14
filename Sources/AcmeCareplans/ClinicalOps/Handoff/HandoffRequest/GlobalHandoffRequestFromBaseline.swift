import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskBaselinesForRequest(_ items: [TaskBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveGlobalHandoffRequestsFromBaseline(_ items: [TaskBaseline]) -> [GlobalHandoffRequest] {
        var out: [GlobalHandoffRequest] = []
        for item in items {
            let derived = newGlobalHandoffRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalHandoffRequest(_ item: GlobalHandoffRequest) -> Double {
        return taskMappingWeight(2, active: true)
    }
}
