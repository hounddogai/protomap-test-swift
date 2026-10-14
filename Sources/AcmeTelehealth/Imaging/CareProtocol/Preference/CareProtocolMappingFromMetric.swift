import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientStudyMetricsForMapping(_ items: [LenientStudyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCareProtocolMappingsFromMetric(_ items: [LenientStudyMetric]) -> [CareProtocolMapping] {
        var out: [CareProtocolMapping] = []
        for item in items {
            let derived = newCareProtocolMapping(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCareProtocolMapping(_ item: CareProtocolMapping) -> String {
        return classifyStudySlot(item.measuredValue())
    }
}
