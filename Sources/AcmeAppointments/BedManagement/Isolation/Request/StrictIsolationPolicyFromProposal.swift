import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackDischargePlanProposalsForPolicy(_ items: [FallbackDischargePlanProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictIsolationPoliciesFromProposal(_ items: [FallbackDischargePlanProposal]) -> [StrictIsolationPolicy] {
        var out: [StrictIsolationPolicy] = []
        for item in items {
            let derived = newStrictIsolationPolicy(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStrictIsolationPolicy(_ item: StrictIsolationPolicy) -> String {
        return dischargePlanProposalBucket(item.effectiveValue())
    }
}
