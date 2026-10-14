import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalOvertimeRecordsForRollup(_ items: [SeasonalOvertimeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveWeightedCredentialRollupsFromRecord(_ items: [SeasonalOvertimeRecord]) -> [WeightedCredentialRollup] {
        var out: [WeightedCredentialRollup] = []
        for item in items {
            let derived = newWeightedCredentialRollup(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceWeightedCredentialRollup(_ item: WeightedCredentialRollup) -> String {
        return regionalOvertimeMappingBucket(item.weightedExposure())
    }
}
