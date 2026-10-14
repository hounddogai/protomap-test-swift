import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedRevocationBaselinesForProposal(_ items: [BatchedRevocationBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCappedProxyProposalsFromBaseline(_ items: [BatchedRevocationBaseline]) -> [CappedProxyProposal] {
        var out: [CappedProxyProposal] = []
        for item in items {
            let derived = newCappedProxyProposal(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planCappedProxyProposal(_ item: CappedProxyProposal) -> String {
        return classifyCappedRevocationBundle(item.measuredValue())
    }
}
