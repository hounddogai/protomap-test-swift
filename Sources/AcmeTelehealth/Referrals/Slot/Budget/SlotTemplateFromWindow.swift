import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureWindowsForTemplate(_ items: [SeasonalClosureWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSlotTemplatesFromWindow(_ items: [SeasonalClosureWindow]) -> [SlotTemplate] {
        var out: [SlotTemplate] = []
        for item in items {
            let derived = newSlotTemplate(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifySlotTemplate(_ item: SlotTemplate) -> String {
        return classifySeasonalClosureWindow(item.netVolume())
    }
}
