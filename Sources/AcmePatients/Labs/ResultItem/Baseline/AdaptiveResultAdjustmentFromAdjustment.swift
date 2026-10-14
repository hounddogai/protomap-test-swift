import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeAdjustmentsForAdjustment(_ items: [ReferenceRangeAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveResultAdjustmentsFromAdjustment(_ items: [ReferenceRangeAdjustment]) -> [AdaptiveResultAdjustment] {
        var out: [AdaptiveResultAdjustment] = []
        for item in items {
            let derived = newAdaptiveResultAdjustment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchAdaptiveResultAdjustment(_ item: AdaptiveResultAdjustment) -> String {
        return referenceRangeClaimBucket(item.netValue())
    }
}
