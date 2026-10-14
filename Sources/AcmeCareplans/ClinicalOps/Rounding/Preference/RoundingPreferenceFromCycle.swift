import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryHandoffCyclesForPreference(_ items: [PrimaryHandoffCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRoundingPreferencesFromCycle(_ items: [PrimaryHandoffCycle]) -> [RoundingPreference] {
        var out: [RoundingPreference] = []
        for item in items {
            let derived = newRoundingPreference(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeRoundingPreference(_ item: RoundingPreference) -> String {
        return classifyScheduledHandoffWindow(item.measuredValue())
    }
}
