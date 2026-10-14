import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackFollowUpBaselinesForWindow(_ items: [FallbackFollowUpBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSeasonalClosureWindowsFromBaseline(_ items: [FallbackFollowUpBaseline]) -> [SeasonalClosureWindow] {
        var out: [SeasonalClosureWindow] = []
        for item in items {
            let derived = newSeasonalClosureWindow(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchSeasonalClosureWindow(_ item: SeasonalClosureWindow) -> String {
        return followUpEntryBucket(item.measuredValue())
    }
}
