import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSeasonalInteractionAgreementsForGroup(_ items: [SeasonalInteractionAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveWeightedFormularyGroupsFromAgreement(_ items: [SeasonalInteractionAgreement]) -> [WeightedFormularyGroup] {
        var out: [WeightedFormularyGroup] = []
        for item in items {
            let derived = newWeightedFormularyGroup(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedFormularyGroup(_ item: WeightedFormularyGroup) -> String {
        return normalizeSeasonalInteractionAgreementCode(item.code)
    }
}
