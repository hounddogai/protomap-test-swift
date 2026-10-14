import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureMilestonesForPreference(_ items: [DisclosureMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveWitnessPreferencesFromMilestone(_ items: [DisclosureMilestone]) -> [WitnessPreference] {
        var out: [WitnessPreference] = []
        for item in items {
            let derived = newWitnessPreference(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyWitnessPreferenceExtra(_ item: WitnessPreference) -> String {
        return normalizeDisclosureSegmentCode(item.code)
    }
}
