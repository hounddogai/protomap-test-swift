import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingForecastsForProposal(_ items: [RoundingForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveHandoffProposalsFromForecast(_ items: [RoundingForecast]) -> [HandoffProposal] {
        var out: [HandoffProposal] = []
        for item in items {
            let derived = newHandoffProposal(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateHandoffProposal(_ item: HandoffProposal) -> String {
        return normalizeRoundingForecastCode(item.code)
    }
}
