import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalOutreachAgreementsForProposal(_ items: [GlobalOutreachAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePrimaryOutreachProposalsFromAgreement(_ items: [GlobalOutreachAgreement]) -> [PrimaryOutreachProposal] {
        var out: [PrimaryOutreachProposal] = []
        for item in items {
            let derived = newPrimaryOutreachProposal(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePrimaryOutreachProposal(_ item: PrimaryOutreachProposal) -> String {
        return classifyAdaptiveOutreachTier(item.adjustedValue())
    }
}
