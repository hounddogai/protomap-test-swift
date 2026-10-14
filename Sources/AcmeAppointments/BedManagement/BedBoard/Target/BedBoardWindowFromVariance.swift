import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanVariancesForWindow(_ items: [DischargePlanVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveBedBoardWindowsFromVariance(_ items: [DischargePlanVariance]) -> [BedBoardWindow] {
        var out: [BedBoardWindow] = []
        for item in items {
            let derived = newBedBoardWindow(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBedBoardWindow(_ item: BedBoardWindow) -> Double {
        return dischargePlanReviewWeight(9, active: true)
    }
}
