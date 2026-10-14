import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelDigestsForPreference(_ items: [AdaptivePanelDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveStrictAccessionPreferencesFromDigest(_ items: [AdaptivePanelDigest]) -> [StrictAccessionPreference] {
        var out: [StrictAccessionPreference] = []
        for item in items {
            let derived = newStrictAccessionPreference(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveStrictAccessionPreference(_ item: StrictAccessionPreference) -> String {
        return panelDraftBucket(item.effectiveValue())
    }
}
