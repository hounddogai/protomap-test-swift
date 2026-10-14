import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityCheckpointsForWindow(_ items: [EligibilityCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalClosureWindowsFromCheckpoint(_ items: [EligibilityCheckpoint]) -> [SeasonalClosureWindow] {
        var out: [SeasonalClosureWindow] = []
        for item in items {
            let derived = newSeasonalClosureWindow(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSeasonalClosureWindow(_ item: SeasonalClosureWindow) -> String {
        return normalizeEligibilityNoticeCode(item.code)
    }
}
