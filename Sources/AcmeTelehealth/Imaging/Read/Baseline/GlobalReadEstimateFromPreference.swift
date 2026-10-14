import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeBatchedPriorityPreferencesForEstimate(_ items: [BatchedPriorityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveGlobalReadEstimatesFromPreference(_ items: [BatchedPriorityPreference]) -> [GlobalReadEstimate] {
        var out: [GlobalReadEstimate] = []
        for item in items {
            let derived = newGlobalReadEstimate(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalReadEstimate(_ item: GlobalReadEstimate) -> String {
        return normalizeBatchedPriorityPreferenceCode(item.code)
    }
}
