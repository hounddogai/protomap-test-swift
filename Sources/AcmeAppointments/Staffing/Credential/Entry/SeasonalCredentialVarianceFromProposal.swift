import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolProposalsForVariance(_ items: [FloatPoolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveSeasonalCredentialVariancesFromProposal(_ items: [FloatPoolProposal]) -> [SeasonalCredentialVariance] {
        var out: [SeasonalCredentialVariance] = []
        for item in items {
            let derived = newSeasonalCredentialVariance(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectSeasonalCredentialVariance(_ item: SeasonalCredentialVariance) -> String {
        return normalizeFloatPoolRollupCode(item.code)
    }
}
