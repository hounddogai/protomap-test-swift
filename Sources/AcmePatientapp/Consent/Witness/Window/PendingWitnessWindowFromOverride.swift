import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageOverridesForWindowWindow(_ items: [LanguageOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePendingWitnessWindowsFromOverride(_ items: [LanguageOverride]) -> [PendingWitnessWindow] {
        var out: [PendingWitnessWindow] = []
        for item in items {
            let derived = newPendingWitnessWindow(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePendingWitnessWindow(_ item: PendingWitnessWindow) -> String {
        return legacyLanguageTemplateBucket(item.weightedVolume())
    }
}
