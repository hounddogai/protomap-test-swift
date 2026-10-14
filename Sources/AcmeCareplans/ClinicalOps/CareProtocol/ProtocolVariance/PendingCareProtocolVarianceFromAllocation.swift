import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingAllocationsForVariance(_ items: [SeasonalRoundingAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingCareProtocolVariancesFromAllocation(_ items: [SeasonalRoundingAllocation]) -> [PendingCareProtocolVariance] {
        var out: [PendingCareProtocolVariance] = []
        for item in items {
            let derived = newPendingCareProtocolVariance(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scorePendingCareProtocolVariance(_ item: PendingCareProtocolVariance) -> String {
        return classifySeasonalRoundingAllocation(item.adjustedTotal())
    }
}
