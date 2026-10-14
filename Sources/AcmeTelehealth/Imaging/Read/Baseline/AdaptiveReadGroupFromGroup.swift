import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistGroupsForGroup(_ items: [WorklistGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveReadGroupsFromGroup(_ items: [WorklistGroup]) -> [AdaptiveReadGroup] {
        var out: [AdaptiveReadGroup] = []
        for item in items {
            let derived = newAdaptiveReadGroup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveReadGroup(_ item: AdaptiveReadGroup) -> String {
        return normalizeWorklistDraftCode(item.code)
    }
}
