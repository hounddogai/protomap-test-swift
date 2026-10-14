import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveIsolationPoliciesForAgreement(_ items: [AdaptiveIsolationPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCleaningAgreementsFromPolicy(_ items: [AdaptiveIsolationPolicy]) -> [CleaningAgreement] {
        var out: [CleaningAgreement] = []
        for item in items {
            let derived = newCleaningAgreement(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCleaningAgreement(_ item: CleaningAgreement) -> String {
        return adaptiveIsolationPolicyBucket(item.adjustedValue())
    }
}
