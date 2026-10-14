import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedConsentFormLedgersForBaseline(_ items: [WeightedConsentFormLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRevocationBaselinesFromLedger(_ items: [WeightedConsentFormLedger]) -> [RevocationBaseline] {
        var out: [RevocationBaseline] = []
        for item in items {
            let derived = newRevocationBaseline(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveRevocationBaseline(_ item: RevocationBaseline) -> String {
        return consentFormProposalBucket(item.effectiveTotal())
    }
}
