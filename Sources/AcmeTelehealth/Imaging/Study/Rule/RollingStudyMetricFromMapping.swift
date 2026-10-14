import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadMappingsForMetric(_ items: [ReadMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRollingStudyMetricsFromMapping(_ items: [ReadMapping]) -> [RollingStudyMetric] {
        var out: [RollingStudyMetric] = []
        for item in items {
            let derived = newRollingStudyMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreRollingStudyMetric(_ item: RollingStudyMetric) -> String {
        return readOverrideBucket(item.effectiveVolume())
    }
}
