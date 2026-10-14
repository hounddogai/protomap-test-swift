import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalResultPreferencesForWindow(_ items: [GlobalResultPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictResultWindowsFromPreference(_ items: [GlobalResultPreference]) -> [StrictResultWindow] {
        var out: [StrictResultWindow] = []
        for item in items {
            let derived = newStrictResultWindow(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchStrictResultWindow(_ item: StrictResultWindow) -> Double {
        return resultSummaryWeight(4, active: true)
    }
}
