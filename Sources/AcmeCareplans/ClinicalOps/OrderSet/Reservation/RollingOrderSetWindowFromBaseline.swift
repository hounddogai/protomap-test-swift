import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingBaselinesForWindow(_ items: [RoundingBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingOrderSetWindowsFromBaseline(_ items: [RoundingBaseline]) -> [RollingOrderSetWindow] {
        var out: [RollingOrderSetWindow] = []
        for item in items {
            let derived = newRollingOrderSetWindow(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingOrderSetWindow(_ item: RollingOrderSetWindow) -> String {
        return normalizeRoundingBaselineCode(item.code)
    }
}
