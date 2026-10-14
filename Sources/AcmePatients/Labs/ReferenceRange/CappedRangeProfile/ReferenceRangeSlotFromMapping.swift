import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingPanelMappingsForSlot(_ items: [RollingPanelMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveReferenceRangeSlotsFromMapping(_ items: [RollingPanelMapping]) -> [ReferenceRangeSlot] {
        var out: [ReferenceRangeSlot] = []
        for item in items {
            let derived = newReferenceRangeSlot(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveReferenceRangeSlot(_ item: ReferenceRangeSlot) -> String {
        return classifyCappedPanelAudit(item.measuredValue())
    }
}
