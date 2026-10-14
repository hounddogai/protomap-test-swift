import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementProposalsForVariance(_ items: [StatementProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRemittanceVariancesFromProposal(_ items: [StatementProposal]) -> [RemittanceVariance] {
        var out: [RemittanceVariance] = []
        for item in items {
            let derived = newRemittanceVariance(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRemittanceVariance(_ item: RemittanceVariance) -> String {
        return normalizeStatementProposalCode(item.code)
    }
}
