import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientReferenceRangeWindowsForProposal(_ items: [LenientReferenceRangeWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLegacyAccessionProposalsFromWindow(_ items: [LenientReferenceRangeWindow]) -> [LegacyAccessionProposal] {
        var out: [LegacyAccessionProposal] = []
        for item in items {
            let derived = newLegacyAccessionProposal(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyAccessionProposal(_ item: LegacyAccessionProposal) -> String {
        return regionalReferenceRangeSlotBucket(item.adjustedVolume())
    }
}
