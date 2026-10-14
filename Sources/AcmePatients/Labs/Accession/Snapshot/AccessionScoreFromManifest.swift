import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryCourierManifestsForScore(_ items: [PrimaryCourierManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAccessionScoresFromManifest(_ items: [PrimaryCourierManifest]) -> [AccessionScore] {
        var out: [AccessionScore] = []
        for item in items {
            let derived = newAccessionScore(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAccessionScore(_ item: AccessionScore) -> String {
        return defaultCourierMetricBucket(item.effectiveValue())
    }
}
