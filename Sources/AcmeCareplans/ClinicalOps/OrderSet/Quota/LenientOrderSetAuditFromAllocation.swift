import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingAllocationsForAudit(_ items: [SeasonalRoundingAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientOrderSetAuditsFromAllocation(_ items: [SeasonalRoundingAllocation]) -> [LenientOrderSetAudit] {
        var out: [LenientOrderSetAudit] = []
        for item in items {
            let derived = newLenientOrderSetAudit(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientOrderSetAudit(_ item: LenientOrderSetAudit) -> String {
        return normalizeFallbackRoundingSlotCode(item.code)
    }
}
