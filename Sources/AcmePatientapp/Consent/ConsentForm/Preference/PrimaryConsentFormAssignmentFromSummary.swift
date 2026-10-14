import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationSummariesForAssignment(_ items: [RevocationSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func derivePrimaryConsentFormAssignmentsFromSummary(_ items: [RevocationSummary]) -> [PrimaryConsentFormAssignment] {
        var out: [PrimaryConsentFormAssignment] = []
        for item in items {
            let derived = newPrimaryConsentFormAssignment(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePrimaryConsentFormAssignment(_ item: PrimaryConsentFormAssignment) -> Double {
        return adaptiveRevocationExceptionWeight(9, active: true)
    }

    static func summarizeWeightedProxySummariesForAssignment(_ items: [WeightedProxySummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimaryConsentFormAssignmentsFromSummaryExtra(_ items: [WeightedProxySummary]) -> [PrimaryConsentFormAssignment] {
        var out: [PrimaryConsentFormAssignment] = []
        for item in items {
            let derived = newPrimaryConsentFormAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryConsentFormAssignment(_ item: PrimaryConsentFormAssignment) -> String {
        return normalizeScheduledProxyDraftCode(item.code)
    }
}
