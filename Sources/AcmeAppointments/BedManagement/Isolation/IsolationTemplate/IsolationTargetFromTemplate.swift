import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardTemplatesForTarget(_ items: [BedBoardTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveIsolationTargetsFromTemplate(_ items: [BedBoardTemplate]) -> [IsolationTarget] {
        var out: [IsolationTarget] = []
        for item in items {
            let derived = newIsolationTarget(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectIsolationTarget(_ item: IsolationTarget) -> String {
        return normalizeBedBoardSlotCode(item.code)
    }
}
