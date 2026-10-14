import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedCleaningAgreementsForProposal(_ items: [CappedCleaningAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveFallbackDischargePlanProposalsFromAgreement(_ items: [CappedCleaningAgreement]) -> [FallbackDischargePlanProposal] {
        var out: [FallbackDischargePlanProposal] = []
        for item in items {
            let derived = newFallbackDischargePlanProposal(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeFallbackDischargePlanProposal(_ item: FallbackDischargePlanProposal) -> Double {
        return cappedCleaningAgreementWeight(6, active: true)
    }
}
