import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftThresholdsForWindow(_ items: [StrictShiftThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveManualCredentialWindowsFromThreshold(_ items: [StrictShiftThreshold]) -> [ManualCredentialWindow] {
        var out: [ManualCredentialWindow] = []
        for item in items {
            let derived = newManualCredentialWindow(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualCredentialWindow(_ item: ManualCredentialWindow) -> Double {
        return cappedShiftSnapshotWeight(8, active: true)
    }
}
