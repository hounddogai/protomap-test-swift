import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedWorklistNoticesForMapping(_ items: [CappedWorklistNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveGlobalReadMappingsFromNotice(_ items: [CappedWorklistNotice]) -> [GlobalReadMapping] {
        var out: [GlobalReadMapping] = []
        for item in items {
            let derived = newGlobalReadMapping(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalReadMapping(_ item: GlobalReadMapping) -> String {
        return classifySeasonalWorklistPreference(item.weightedTotal())
    }
}
