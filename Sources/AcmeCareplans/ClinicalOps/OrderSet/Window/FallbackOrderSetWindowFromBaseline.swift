import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertBaselinesForWindow(_ items: [AlertBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveFallbackOrderSetWindowsFromBaseline(_ items: [AlertBaseline]) -> [FallbackOrderSetWindow] {
        var out: [FallbackOrderSetWindow] = []
        for item in items {
            let derived = newFallbackOrderSetWindow(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackOrderSetWindow(_ item: FallbackOrderSetWindow) -> Double {
        return alertBaselineWeight(1, active: true)
    }
}
