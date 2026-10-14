import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSlotsForMapping(_ items: [ReferenceRangeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalReferenceRangeMappingsFromSlot(_ items: [ReferenceRangeSlot]) -> [RegionalReferenceRangeMapping] {
        var out: [RegionalReferenceRangeMapping] = []
        for item in items {
            let derived = newRegionalReferenceRangeMapping(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeRegionalReferenceRangeMapping(_ item: RegionalReferenceRangeMapping) -> String {
        return classifyLegacyReferenceRangeProfile(item.netVolume())
    }
}
