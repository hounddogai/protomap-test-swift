import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationProposalsForMapping(_ items: [AuthorizationProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDenialMappingsFromProposal(_ items: [AuthorizationProposal]) -> [DenialMapping] {
        var out: [DenialMapping] = []
        for item in items {
            let derived = newDenialMapping(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeDenialMapping(_ item: DenialMapping) -> String {
        return classifyAuthorizationBatch(item.weightedExposure())
    }
}
