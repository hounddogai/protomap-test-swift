import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureBaselinesForDraft(_ items: [ClosureBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSeasonalClosureDraftsFromBaseline(_ items: [ClosureBaseline]) -> [SeasonalClosureDraft] {
        var out: [SeasonalClosureDraft] = []
        for item in items {
            let derived = newSeasonalClosureDraft(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeSeasonalClosureDraft(_ item: SeasonalClosureDraft) -> Double {
        return closureBaselineWeight(7, active: true)
    }
}
