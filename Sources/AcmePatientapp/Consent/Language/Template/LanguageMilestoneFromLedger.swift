import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormLedgersForMilestone(_ items: [ConsentFormLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLanguageMilestonesFromLedger(_ items: [ConsentFormLedger]) -> [LanguageMilestone] {
        var out: [LanguageMilestone] = []
        for item in items {
            let derived = newLanguageMilestone(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeLanguageMilestone(_ item: LanguageMilestone) -> String {
        return consentFormMetricBucket(item.effectiveLoad())
    }
}
