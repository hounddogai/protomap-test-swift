import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistRecordsForBaseline(_ items: [WorklistRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalCareProtocolBaselinesFromRecord(_ items: [WorklistRecord]) -> [GlobalCareProtocolBaseline] {
        var out: [GlobalCareProtocolBaseline] = []
        for item in items {
            let derived = newGlobalCareProtocolBaseline(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeGlobalCareProtocolBaseline(_ item: GlobalCareProtocolBaseline) -> String {
        return classifyWorklistPolicy(item.projectedValue())
    }
}
