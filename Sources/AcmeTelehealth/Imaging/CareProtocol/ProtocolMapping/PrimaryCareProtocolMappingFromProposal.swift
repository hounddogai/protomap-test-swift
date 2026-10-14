import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadProposalsForMapping(_ items: [LenientReadProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePrimaryCareProtocolMappingsFromProposal(_ items: [LenientReadProposal]) -> [PrimaryCareProtocolMapping] {
        var out: [PrimaryCareProtocolMapping] = []
        for item in items {
            let derived = newPrimaryCareProtocolMapping(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryCareProtocolMapping(_ item: PrimaryCareProtocolMapping) -> String {
        return lenientReadProposalBucket(item.projectedLoad())
    }
}
