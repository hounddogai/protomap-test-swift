import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientDischargePlanWindowsForPlan(_ items: [LenientDischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientCensusPlansFromWindow(_ items: [LenientDischargePlanWindow]) -> [LenientCensusPlan] {
        var out: [LenientCensusPlan] = []
        for item in items {
            let derived = newLenientCensusPlan(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveLenientCensusPlan(_ item: LenientCensusPlan) -> String {
        return normalizeLenientDischargePlanWindowCode(item.code)
    }
}
