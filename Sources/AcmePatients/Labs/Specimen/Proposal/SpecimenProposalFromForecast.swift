import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultForecastsForProposal(_ items: [ResultForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveSpecimenProposalsFromForecast(_ items: [ResultForecast]) -> [SpecimenProposal] {
        var out: [SpecimenProposal] = []
        for item in items {
            let derived = newSpecimenProposal(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignSpecimenProposal(_ item: SpecimenProposal) -> String {
        return classifyResultScore(item.measuredValue())
    }
}
