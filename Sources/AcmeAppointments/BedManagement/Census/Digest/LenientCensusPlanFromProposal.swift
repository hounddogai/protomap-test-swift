import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCensusProposalsForPlan(_ items: [PrimaryCensusProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLenientCensusPlansFromProposal(_ items: [PrimaryCensusProposal]) -> [LenientCensusPlan] {
        var out: [LenientCensusPlan] = []
        for item in items {
            let derived = newLenientCensusPlan(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLenientCensusPlan(_ item: LenientCensusPlan) -> String {
        return censusDigestBucket(item.weightedLoad())
    }
}
