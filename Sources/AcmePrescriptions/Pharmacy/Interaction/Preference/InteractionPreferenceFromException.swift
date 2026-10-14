import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultDispenseExceptionsForPreference(_ items: [DefaultDispenseException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveInteractionPreferencesFromException(_ items: [DefaultDispenseException]) -> [InteractionPreference] {
        var out: [InteractionPreference] = []
        for item in items {
            let derived = newInteractionPreference(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectInteractionPreference(_ item: InteractionPreference) -> String {
        return globalDispenseSummaryBucket(item.adjustedLoad())
    }
}
