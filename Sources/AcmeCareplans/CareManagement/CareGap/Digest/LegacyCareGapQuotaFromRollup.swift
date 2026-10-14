import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedProgramRollupsForQuota(_ items: [WeightedProgramRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyCareGapQuotasFromRollup(_ items: [WeightedProgramRollup]) -> [LegacyCareGapQuota] {
        var out: [LegacyCareGapQuota] = []
        for item in items {
            let derived = newLegacyCareGapQuota(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveLegacyCareGapQuota(_ item: LegacyCareGapQuota) -> String {
        return classifyCappedProgramClaim(item.weightedVolume())
    }
}
