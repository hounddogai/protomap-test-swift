import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistDigestsForBundle(_ items: [WorklistDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLegacyModalityBundlesFromDigest(_ items: [WorklistDigest]) -> [LegacyModalityBundle] {
        var out: [LegacyModalityBundle] = []
        for item in items {
            let derived = newLegacyModalityBundle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyModalityBundle(_ item: LegacyModalityBundle) -> String {
        return classifyWorklistDigest(item.netLoad())
    }
}
