import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceProposalsForRequest(_ items: [RemittanceProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredRemittanceRequestsFromProposal(_ items: [RemittanceProposal]) -> [TieredRemittanceRequest] {
        var out: [TieredRemittanceRequest] = []
        for item in items {
            let derived = newTieredRemittanceRequest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchTieredRemittanceRequest(_ item: TieredRemittanceRequest) -> Double {
        return weightedRemittanceRequestWeight(9, active: true)
    }
}
