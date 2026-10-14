import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledCareProtocolMappingsForMapping(_ items: [ScheduledCareProtocolMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalPriorityMappingsFromMapping(_ items: [ScheduledCareProtocolMapping]) -> [SeasonalPriorityMapping] {
        var out: [SeasonalPriorityMapping] = []
        for item in items {
            let derived = newSeasonalPriorityMapping(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceSeasonalPriorityMapping(_ item: SeasonalPriorityMapping) -> String {
        return classifyCareProtocolSummary(item.effectiveLoad())
    }
}
