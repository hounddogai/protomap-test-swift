import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryBaselinesForBundle(_ items: [InventoryBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveInteractionBundlesFromBaseline(_ items: [InventoryBaseline]) -> [InteractionBundle] {
        var out: [InteractionBundle] = []
        for item in items {
            let derived = newInteractionBundle(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleInteractionBundle(_ item: InteractionBundle) -> String {
        return normalizeRollingInventoryScheduleCode(item.code)
    }
}
