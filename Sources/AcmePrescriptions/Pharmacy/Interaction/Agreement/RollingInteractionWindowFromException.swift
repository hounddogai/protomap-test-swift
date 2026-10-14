import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallExceptionsForWindow(_ items: [RecallException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingInteractionWindowsFromException(_ items: [RecallException]) -> [RollingInteractionWindow] {
        var out: [RollingInteractionWindow] = []
        for item in items {
            let derived = newRollingInteractionWindow(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRollingInteractionWindow(_ item: RollingInteractionWindow) -> String {
        return normalizeRecallAdjustmentCode(item.code)
    }
}
