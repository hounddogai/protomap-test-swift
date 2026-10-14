import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationProposalsForSegment(_ items: [RevocationProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRevocationSegmentsFromProposal(_ items: [RevocationProposal]) -> [RevocationSegment] {
        var out: [RevocationSegment] = []
        for item in items {
            let derived = newRevocationSegment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRevocationSegment(_ item: RevocationSegment) -> String {
        return revocationAssignmentBucket(item.weightedTotal())
    }
}
