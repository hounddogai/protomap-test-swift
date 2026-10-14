import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictBedBoardVariancesForProposal(_ items: [StrictBedBoardVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveIsolationProposalsFromVariance(_ items: [StrictBedBoardVariance]) -> [IsolationProposal] {
        var out: [IsolationProposal] = []
        for item in items {
            let derived = newIsolationProposal(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyIsolationProposal(_ item: IsolationProposal) -> String {
        return classifyLegacyBedBoardReview(item.projectedTotal())
    }
}
