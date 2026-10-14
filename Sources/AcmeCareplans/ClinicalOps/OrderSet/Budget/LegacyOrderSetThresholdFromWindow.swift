import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyTaskWindowsForThreshold(_ items: [LegacyTaskWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyOrderSetThresholdsFromWindow(_ items: [LegacyTaskWindow]) -> [LegacyOrderSetThreshold] {
        var out: [LegacyOrderSetThreshold] = []
        for item in items {
            let derived = newLegacyOrderSetThreshold(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLegacyOrderSetThreshold(_ item: LegacyOrderSetThreshold) -> String {
        return normalizeTaskTemplateCode(item.code)
    }
}
