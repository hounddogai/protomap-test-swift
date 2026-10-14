import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientCareGapRulesForProposal(_ items: [LenientCareGapRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLenientOutreachProposalsFromRule(_ items: [LenientCareGapRule]) -> [LenientOutreachProposal] {
        var out: [LenientOutreachProposal] = []
        for item in items {
            let derived = newLenientOutreachProposal(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLenientOutreachProposal(_ item: LenientOutreachProposal) -> Double {
        return adaptiveCareGapOverrideWeight(7, active: true)
    }
}
