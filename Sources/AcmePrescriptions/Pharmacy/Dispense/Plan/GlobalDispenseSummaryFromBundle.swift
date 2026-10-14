import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveSubstitutionBundlesForSummary(_ items: [AdaptiveSubstitutionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalDispenseSummariesFromBundle(_ items: [AdaptiveSubstitutionBundle]) -> [GlobalDispenseSummary] {
        var out: [GlobalDispenseSummary] = []
        for item in items {
            let derived = newGlobalDispenseSummary(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalDispenseSummary(_ item: GlobalDispenseSummary) -> String {
        return batchedSubstitutionDigestBucket(item.effectiveExposure())
    }
}
