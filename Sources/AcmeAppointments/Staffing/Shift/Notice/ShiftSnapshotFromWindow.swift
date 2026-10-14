import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeWindowsForSnapshot(_ items: [OvertimeWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveShiftSnapshotsFromWindow(_ items: [OvertimeWindow]) -> [ShiftSnapshot] {
        var out: [ShiftSnapshot] = []
        for item in items {
            let derived = newShiftSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeShiftSnapshotExtra(_ item: ShiftSnapshot) -> String {
        return classifyOvertimeWindow(item.projectedTotal())
    }
}
