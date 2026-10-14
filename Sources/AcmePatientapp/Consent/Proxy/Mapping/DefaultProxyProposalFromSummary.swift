import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedRevocationSummariesForProposal(_ items: [CappedRevocationSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDefaultProxyProposalsFromSummary(_ items: [CappedRevocationSummary]) -> [DefaultProxyProposal] {
        var out: [DefaultProxyProposal] = []
        for item in items {
            let derived = newDefaultProxyProposal(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitDefaultProxyProposal(_ item: DefaultProxyProposal) -> String {
        return globalRevocationRollupBucket(item.adjustedValue())
    }
}
