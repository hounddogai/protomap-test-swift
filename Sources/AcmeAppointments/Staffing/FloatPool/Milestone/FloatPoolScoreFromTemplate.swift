import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackShiftTemplatesForScore(_ items: [FallbackShiftTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFloatPoolScoresFromTemplate(_ items: [FallbackShiftTemplate]) -> [FloatPoolScore] {
        var out: [FloatPoolScore] = []
        for item in items {
            let derived = newFloatPoolScore(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileFloatPoolScore(_ item: FloatPoolScore) -> String {
        return classifyStrictShiftBundle(item.adjustedExposure())
    }
}
