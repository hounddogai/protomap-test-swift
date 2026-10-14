import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledPanelScoresForRequest(_ items: [ScheduledPanelScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRollingReferenceRangeRequestsFromScore(_ items: [ScheduledPanelScore]) -> [RollingReferenceRangeRequest] {
        var out: [RollingReferenceRangeRequest] = []
        for item in items {
            let derived = newRollingReferenceRangeRequest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingReferenceRangeRequest(_ item: RollingReferenceRangeRequest) -> String {
        return normalizeScheduledPanelScoreCode(item.code)
    }
}
