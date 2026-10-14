import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalFormularyPreferencesForTemplate(_ items: [GlobalFormularyPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePrimaryInteractionTemplatesFromPreference(_ items: [GlobalFormularyPreference]) -> [PrimaryInteractionTemplate] {
        var out: [PrimaryInteractionTemplate] = []
        for item in items {
            let derived = newPrimaryInteractionTemplate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchPrimaryInteractionTemplate(_ item: PrimaryInteractionTemplate) -> String {
        return scheduledFormularyMilestoneBucket(item.projectedVolume())
    }
}
