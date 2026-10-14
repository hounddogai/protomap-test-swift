import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanTemplatesForSlot(_ items: [DischargePlanTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveBedBoardSlotsFromTemplate(_ items: [DischargePlanTemplate]) -> [BedBoardSlot] {
        var out: [BedBoardSlot] = []
        for item in items {
            let derived = newBedBoardSlot(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeBedBoardSlot(_ item: BedBoardSlot) -> String {
        return dischargePlanBudgetBucket(item.adjustedExposure())
    }
}
