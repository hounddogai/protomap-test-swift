import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientGoalVariancesForQuota(_ items: [LenientGoalVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCappedCareGapQuotasFromVariance(_ items: [LenientGoalVariance]) -> [CappedCareGapQuota] {
        var out: [CappedCareGapQuota] = []
        for item in items {
            let derived = newCappedCareGapQuota(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCappedCareGapQuota(_ item: CappedCareGapQuota) -> Double {
        return fallbackGoalClaimWeight(2, active: true)
    }
}
