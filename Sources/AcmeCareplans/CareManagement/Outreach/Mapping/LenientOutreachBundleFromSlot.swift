import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientOutreachSlotsForBundle(_ items: [LenientOutreachSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientOutreachBundlesFromSlot(_ items: [LenientOutreachSlot]) -> [LenientOutreachBundle] {
        var out: [LenientOutreachBundle] = []
        for item in items {
            let derived = newLenientOutreachBundle(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientOutreachBundle(_ item: LenientOutreachBundle) -> Double {
        return manualOutreachAssignmentWeight(5, active: true)
    }
}
