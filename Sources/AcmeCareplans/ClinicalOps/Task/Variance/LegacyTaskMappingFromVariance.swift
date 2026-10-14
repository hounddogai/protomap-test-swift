import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetVariancesForMapping(_ items: [OrderSetVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLegacyTaskMappingsFromVariance(_ items: [OrderSetVariance]) -> [LegacyTaskMapping] {
        var out: [LegacyTaskMapping] = []
        for item in items {
            let derived = newLegacyTaskMapping(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankLegacyTaskMapping(_ item: LegacyTaskMapping) -> String {
        return normalizeOrderSetVarianceCode(item.code)
    }
}
