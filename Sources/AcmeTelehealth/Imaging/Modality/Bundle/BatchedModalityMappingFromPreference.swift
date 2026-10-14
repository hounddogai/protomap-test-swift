import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolPreferencesForMapping(_ items: [CareProtocolPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedModalityMappingsFromPreference(_ items: [CareProtocolPreference]) -> [BatchedModalityMapping] {
        var out: [BatchedModalityMapping] = []
        for item in items {
            let derived = newBatchedModalityMapping(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedModalityMapping(_ item: BatchedModalityMapping) -> String {
        return classifyCareProtocolMapping(item.adjustedValue())
    }
}
