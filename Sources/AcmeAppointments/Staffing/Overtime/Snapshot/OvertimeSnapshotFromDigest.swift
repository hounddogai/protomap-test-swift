import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftDigestsForSnapshot(_ items: [ShiftDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOvertimeSnapshotsFromDigest(_ items: [ShiftDigest]) -> [OvertimeSnapshot] {
        var out: [OvertimeSnapshot] = []
        for item in items {
            let derived = newOvertimeSnapshot(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planOvertimeSnapshot(_ item: OvertimeSnapshot) -> Double {
        return shiftBundleWeight(5, active: true)
    }
}
