import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningRollupsForTemplate(_ items: [CleaningRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBedBoardTemplatesFromRollup(_ items: [CleaningRollup]) -> [BedBoardTemplate] {
        var out: [BedBoardTemplate] = []
        for item in items {
            let derived = newBedBoardTemplate(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBedBoardTemplate(_ item: BedBoardTemplate) -> Double {
        return cleaningSlotWeight(4, active: true)
    }
}
