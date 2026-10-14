import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingAccessionRollupsForBaseline(_ items: [RollingAccessionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReferenceRangeBaselinesFromRollup(_ items: [RollingAccessionRollup]) -> [ReferenceRangeBaseline] {
        var out: [ReferenceRangeBaseline] = []
        for item in items {
            let derived = newReferenceRangeBaseline(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateReferenceRangeBaseline(_ item: ReferenceRangeBaseline) -> Double {
        return globalAccessionTierWeight(8, active: true)
    }
}
