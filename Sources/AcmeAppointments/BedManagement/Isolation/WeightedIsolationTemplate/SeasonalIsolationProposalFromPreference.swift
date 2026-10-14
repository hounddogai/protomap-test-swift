import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultCleaningPreferencesForProposal(_ items: [DefaultCleaningPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveSeasonalIsolationProposalsFromPreference(_ items: [DefaultCleaningPreference]) -> [SeasonalIsolationProposal] {
        var out: [SeasonalIsolationProposal] = []
        for item in items {
            let derived = newSeasonalIsolationProposal(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceSeasonalIsolationProposal(_ item: SeasonalIsolationProposal) -> String {
        return normalizeDefaultCleaningPreferenceCode(item.code)
    }
}
