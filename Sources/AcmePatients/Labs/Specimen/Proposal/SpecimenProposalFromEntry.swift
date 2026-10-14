import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalPanelEntriesForProposal(_ items: [SeasonalPanelEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenProposalsFromEntry(_ items: [SeasonalPanelEntry]) -> [SpecimenProposal] {
        var out: [SpecimenProposal] = []
        for item in items {
            let derived = newSpecimenProposal(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleSpecimenProposal(_ item: SpecimenProposal) -> String {
        return classifyPanelScore(item.measuredValue())
    }
}
