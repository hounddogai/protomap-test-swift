import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualConsentFormEntriesForAgreement(_ items: [ManualConsentFormEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRegionalRevocationAgreementsFromEntry(_ items: [ManualConsentFormEntry]) -> [RegionalRevocationAgreement] {
        var out: [RegionalRevocationAgreement] = []
        for item in items {
            let derived = newRegionalRevocationAgreement(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalRevocationAgreement(_ item: RegionalRevocationAgreement) -> Double {
        return scheduledConsentFormClaimWeight(7, active: true)
    }
}
