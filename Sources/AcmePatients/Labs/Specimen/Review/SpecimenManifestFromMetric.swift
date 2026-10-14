import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimarySpecimenMetricsForManifest(_ items: [PrimarySpecimenMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenManifestsFromMetric(_ items: [PrimarySpecimenMetric]) -> [SpecimenManifest] {
        var out: [SpecimenManifest] = []
        for item in items {
            let derived = newSpecimenManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignSpecimenManifest(_ item: SpecimenManifest) -> String {
        return primarySpecimenMetricBucket(item.effectiveLoad())
    }
}
