import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRollingClosureProfilesForVariance(_ items: [RollingClosureProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveDefaultFollowUpVariancesFromProfile(_ items: [RollingClosureProfile]) -> [DefaultFollowUpVariance] {
        var out: [DefaultFollowUpVariance] = []
        for item in items {
            let derived = newDefaultFollowUpVariance(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDefaultFollowUpVariance(_ item: DefaultFollowUpVariance) -> String {
        return manualClosureScoreBucket(item.weightedExposure())
    }
}
