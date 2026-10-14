import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingStudyCyclesForSnapshot(_ items: [RollingStudyCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReadSnapshotsFromCycle(_ items: [RollingStudyCycle]) -> [ReadSnapshot] {
        var out: [ReadSnapshot] = []
        for item in items {
            let derived = newReadSnapshot(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeReadSnapshot(_ item: ReadSnapshot) -> String {
        return classifyGlobalStudyNotice(item.measuredValue())
    }
}
